import SwiftUI
import GRDB
import ForgeMediaDomain
import ForgeMediaData
import ForgeMediaMedia
import ForgeMediaAI
import ForgeMediaDiagnostics

/// The central observable model for the app shell.
///
/// Holds the job queue, database, engine, and privacy state.
/// Uses GRDB ValueObservation to reactively stream job changes.
@MainActor
@Observable
public final class AppModel {
    public var jobs: [JobRecord] = []
    public var events: [JobEvent] = []
    public var presets: [MediaPreset] = []
    public var activeJobCount: Int = 0
    public var privacyMode: PrivacyMode = .privacyOn
    public var showJobsPanel: Bool = false

    let db: DatabaseService
    let engine: ProcessingEngine
    let localAgent: LocalAgentRouter
    let logger = DiagnosticsLogger.shared

    private var jobRepo: JobRepository
    private var presetRepo: PresetRepository
    private var observationTask: Task<Void, Never>?
    private var eventsObservationTask: Task<Void, Never>?
    private let supportedVideoExtensions: Set<String> = ["mp4", "mov", "mkv", "avi", "m4v", "webm"]

    public init(
        db: DatabaseService,
        engine: ProcessingEngine = FakeProcessingEngine(),
        agent: LocalAgentRouter = StubLocalAgentRouter()
    ) {
        self.db = db
        self.engine = engine
        self.localAgent = agent
        self.jobRepo = JobRepository(db: db)
        self.presetRepo = PresetRepository(db: db)
    }

    // MARK: - Lifecycle

    public func start() {
        do {
            presets = try presetRepo.all()
            jobs = try jobRepo.all()
            events = try jobRepo.recentEvents(limit: 100).reversed()
            activeJobCount = try jobRepo.activeCount()
        } catch {
            Task { await logger.error("app", "Startup failed: \(error.localizedDescription)") }
        }
        startObservation()
        startEventsObservation()
    }

    private func startObservation() {
        observationTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let observation = self.jobRepo.observeAll()
            do {
                for try await updated in observation.values(in: self.db.reader) {
                    self.jobs = updated
                    self.activeJobCount = updated.filter {
                        [.running, .preparing, .probing, .planning, .validating].contains($0.phase)
                    }.count
                }
            } catch {
                await self.logger.error("app", "Observation failed: \(error.localizedDescription)")
            }
        }
    }

    private func startEventsObservation() {
        eventsObservationTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let observation = self.jobRepo.observeRecentEvents(limit: 100)
            do {
                for try await updated in observation.values(in: self.db.reader) {
                    // Stream shows newest at bottom, so reverse the descending query
                    self.events = updated.reversed()
                }
            } catch {
                await self.logger.error("app", "Events observation failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Actions

    public func addJob(url: URL, presetID: String = "convert_h264") {
        guard isSupportedVideo(url) else { return }

        let job = JobRecord(
            title: url.lastPathComponent,
            sourceURL: url,
            presetID: presetID,
            phase: .idle,
            progressLabel: "Ready",
            privacyMode: privacyMode
        )
        do {
            try jobRepo.upsert(job)
            Task { await logger.info("app", "Job added: \(job.title)") }
            Task { await startJob(job) }
        } catch {
            Task { await logger.error("app", "Failed to add job: \(error.localizedDescription)") }
        }
    }

    public func addJobs(urls: [URL], presetID: String = "convert_h264") {
        for url in urls where isSupportedVideo(url) {
            addJob(url: url, presetID: presetID)
        }
    }

    public func addJobs(fromFolder folderURL: URL, recursive: Bool = true, presetID: String = "convert_h264") {
        guard folderURL.hasDirectoryPath else { return }

        let keys: Set<URLResourceKey> = [.isRegularFileKey, .isDirectoryKey]
        guard let enumerator = FileManager.default.enumerator(
            at: folderURL,
            includingPropertiesForKeys: Array(keys),
            options: recursive ? [.skipsHiddenFiles] : [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        ) else {
            return
        }

        var discovered: [URL] = []
        for case let fileURL as URL in enumerator {
            if isSupportedVideo(fileURL) {
                discovered.append(fileURL)
            }
        }

        addJobs(urls: discovered, presetID: presetID)
    }

    private func isSupportedVideo(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return supportedVideoExtensions.contains(ext)
    }

    public func startJob(_ job: JobRecord) async {
        guard let preset = presets.first(where: { $0.id == job.presetID }) else {
            await logger.error("app", "Preset not found: \(job.presetID)")
            return
        }

        do {
            try jobRepo.updateProgress(jobID: job.id, phase: .preparing, fraction: 0, confidence: .estimated, label: "Preparing…", checkpoint: nil)
            try jobRepo.insertEvent(JobEvent(jobID: job.id, phase: .preparing, message: "Starting job"))

            let output = try await engine.run(job, preset: preset) { progress in
                DispatchQueue.main.async { [weak self] in
                    do {
                        try self?.jobRepo.updateProgress(
                            jobID: job.id,
                            phase: progress.phase,
                            fraction: progress.fraction,
                            confidence: progress.confidence,
                            label: progress.label,
                            checkpoint: progress.lastCheckpoint
                        )
                        try self?.jobRepo.insertEvent(JobEvent(
                            jobID: job.id,
                            phase: progress.phase,
                            message: progress.label,
                            progressFraction: progress.fraction,
                            progressConfidence: progress.confidence
                        ))
                    } catch {
                        Task { await self?.logger.error("app", "Progress update failed: \(error.localizedDescription)") }
                    }
                }
            }

            try jobRepo.updateProgress(jobID: job.id, phase: .completed, fraction: 1, confidence: .measured, label: "Complete", checkpoint: nil)
            try jobRepo.insertEvent(JobEvent(jobID: job.id, phase: .completed, message: "Output: \(output.url.lastPathComponent)"))
        } catch is CancellationError {
            try? jobRepo.updateProgress(jobID: job.id, phase: .canceled, fraction: job.progressFraction, confidence: .measured, label: "Canceled", checkpoint: nil)
            try? jobRepo.insertEvent(JobEvent(jobID: job.id, phase: .canceled, message: "Job canceled by user"))
        } catch {
            await logger.error("app", "Job failed: \(error.localizedDescription)")
            try? jobRepo.updateProgress(jobID: job.id, phase: .failed, fraction: job.progressFraction, confidence: .measured, label: error.localizedDescription, checkpoint: nil)
            try? jobRepo.insertEvent(JobEvent(jobID: job.id, phase: .failed, message: error.localizedDescription))
        }
    }

    public func cancelJob(_ job: JobRecord) async {
        await engine.cancel(jobID: job.id)
        try? jobRepo.requestCancellation(jobID: job.id)
    }

    // MARK: - Demo / Visual Activity

    /// Injects a scripted sequence of `JobEvent`s into the database so the
    /// Activity Stream view has visible content even without a real job.
    /// Backs the "Demo" button in the UI; useful for visual review and onboarding.
    public func injectDemoActivity() {
        guard let firstJob = jobs.first else { return }
        let jobID = firstJob.id
        let now = Date()

        let script: [(phase: JobPhase, label: String, fraction: Double, delay: TimeInterval)] = [
            (.preparing, "Preparing job", 0.05, 0),
            (.running, "Probing media metadata", 0.12, 0.4),
            (.running, "Planning segment chunks", 0.22, 0.8),
            (.running, "Decoding segment 1 of 6", 0.34, 1.2),
            (.running, "Applying FFmpeg filter chain", 0.48, 1.6),
            (.running, "Encoding segment 3 of 6", 0.62, 2.0),
            (.running, "Encoding segment 5 of 6", 0.78, 2.4),
            (.validating, "Validating output container", 0.90, 2.8),
            (.completed, "Output written and checksum verified", 1.00, 3.2)
        ]

        for step in script {
            DispatchQueue.main.asyncAfter(deadline: .now() + step.delay) { [weak self] in
                guard let self else { return }
                let event = JobEvent(
                    jobID: jobID,
                    phase: step.phase,
                    message: step.label,
                    progressFraction: step.fraction,
                    progressConfidence: .measured,
                    createdAt: Date()
                )
                try? self.jobRepo.insertEvent(event)
                try? self.jobRepo.updateProgress(
                    jobID: jobID,
                    phase: step.phase,
                    fraction: step.fraction,
                    confidence: .measured,
                    label: step.label,
                    checkpoint: nil
                )
            }
        }
        _ = now
    }
}
