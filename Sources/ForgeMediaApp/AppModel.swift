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

    // MARK: - Language detection state

    /// URLs waiting for language confirmation before enqueuing
    public var pendingURLs: [URL] = []
    public var pendingPresetID: String = "convert_h264"
    /// Root folder URL when pending jobs originated from a folder intake; nil for single-file intake.
    public var pendingRootFolderURL: URL? = nil
    public var detectionResults: [URL: LanguageDetectionResult] = [:]
    public var showLanguageSheet: Bool = false
    public var isDetectingLanguages: Bool = false

    // MARK: - Internal dependencies

    let db: DatabaseService
    let engine: ProcessingEngine
    let localAgent: LocalAgentRouter
    let languageService: LanguageDetectionService
    let logger = DiagnosticsLogger.shared

    private var jobRepo: JobRepository
    private var presetRepo: PresetRepository
    private var observationTask: Task<Void, Never>?
    private var eventsObservationTask: Task<Void, Never>?
    private let supportedVideoExtensions: Set<String> = ["mp4", "mov", "mkv", "avi", "m4v", "webm"]

    public init(
        db: DatabaseService,
        engine: ProcessingEngine = FakeProcessingEngine(),
        agent: LocalAgentRouter = StubLocalAgentRouter(),
        geminiAPIKey: String? = ProcessInfo.processInfo.environment["GEMINI_API_KEY"],
        remoteAIAllowed: Bool = false
    ) {
        self.db = db
        self.engine = engine
        self.localAgent = agent
        self.languageService = LanguageDetectionService(
            geminiAPIKey: geminiAPIKey,
            remoteAIAllowed: remoteAIAllowed
        )
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
                    self.events = updated.reversed()
                }
            } catch {
                await self.logger.error("app", "Events observation failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Intake (Language-Detection Gate)

    /// Primary intake point. Detects languages then shows confirmation sheet.
    public func intakeVideos(urls: [URL], presetID: String = "convert_h264", rootFolderURL: URL? = nil) {
        let videos = urls.filter { isSupportedVideo($0) }
        guard !videos.isEmpty else { return }

        pendingURLs = videos
        pendingPresetID = presetID
        pendingRootFolderURL = rootFolderURL
        detectionResults = [:]
        showLanguageSheet = false
        isDetectingLanguages = true

        Task {
            let results = await languageService.detectBatch(urls: videos)
            await MainActor.run {
                self.detectionResults = results
                self.isDetectingLanguages = false
                self.showLanguageSheet = true
            }
        }
    }

    /// Called when user drops a single file or uses "Select Video".
    public func intakeVideo(url: URL, presetID: String = "convert_h264") {
        intakeVideos(urls: [url], presetID: presetID)
    }

    /// Called when user drops a folder.
    public func intakeFolder(folderURL: URL, recursive: Bool = true, presetID: String = "convert_h264") {
        guard folderURL.hasDirectoryPath else { return }

        let keys: Set<URLResourceKey> = [.isRegularFileKey, .isDirectoryKey]
        guard let enumerator = FileManager.default.enumerator(
            at: folderURL,
            includingPropertiesForKeys: Array(keys),
            options: recursive ? [.skipsHiddenFiles] : [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        ) else { return }

        var discovered: [URL] = []
        for case let fileURL as URL in enumerator {
            if isSupportedVideo(fileURL) {
                discovered.append(fileURL)
            }
        }

        intakeVideos(urls: discovered, presetID: presetID, rootFolderURL: folderURL)
    }

    /// Called by the language sheet when user confirms.
    /// `overrides` maps each URL to the user-confirmed BCP-47 source language code.
    public func confirmLanguagesAndStart(overrides: [URL: String], targetLanguage: String) {
        showLanguageSheet = false
        let urls = pendingURLs
        let presetID = pendingPresetID
        let rootFolderURL = pendingRootFolderURL
        let rawResults = detectionResults
        pendingURLs = []
        pendingRootFolderURL = nil
        detectionResults = [:]

        for url in urls where isSupportedVideo(url) {
            let detected = rawResults[url]?.language.id
            let confirmed = overrides[url]

            let job = JobRecord(
                title: url.lastPathComponent,
                sourceURL: url,
                presetID: presetID,
                phase: .idle,
                progressLabel: "Ready",
                privacyMode: privacyMode,
                detectedSourceLanguage: detected,
                confirmedSourceLanguage: (confirmed != detected) ? confirmed : nil,
                targetLanguage: targetLanguage,
                intakeRootFolderURL: rootFolderURL
            )
            do {
                try jobRepo.upsert(job)
                Task { await logger.info("app", "Job added: \(job.title) [src=\(job.effectiveSourceLanguage) → tgt=\(targetLanguage)]") }
                Task { await startJob(job) }
            } catch {
                Task { await logger.error("app", "Failed to add job: \(error.localizedDescription)") }
            }
        }
    }

    /// Called by the language sheet Cancel button — discard pending queue.
    public func cancelPendingDetection() {
        showLanguageSheet = false
        isDetectingLanguages = false
        pendingURLs = []
        detectionResults = [:]
    }

    // MARK: - Legacy direct-add (used by demo / internal paths)

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

    private func isSupportedVideo(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return supportedVideoExtensions.contains(ext)
    }

    // MARK: - Job execution

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
