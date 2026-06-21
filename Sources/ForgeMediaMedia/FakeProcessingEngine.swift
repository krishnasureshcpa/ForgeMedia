import Foundation
import ForgeMediaDomain
import ForgeMediaDiagnostics

/// A fake ProcessingEngine that simulates media work for UI development.
///
/// - Probe returns plausible mock data after 0.5-1.5s.
/// - Run simulates 3-5 processing segments over 5-10 seconds.
/// - Cancel sets a flag; the engine notices at the next segment boundary.
public final class FakeProcessingEngine: ProcessingEngine, @unchecked Sendable {
    private let logger = DiagnosticsLogger.shared

    // Track active job cancellations by job ID.
    private let lock = NSLock()
    private var cancelledJobIDs: Set<String> = []

    public init() {}

    // MARK: - ProcessingEngine

    public func probe(_ url: URL) async throws -> MediaProbeResult {
        await logger.info("fake.engine", "Probing \(url.lastPathComponent)…")
        try await Task.sleep(for: .milliseconds(Int.random(in: 500...1500)))

        return MediaProbeResult(
            duration: Double.random(in: 60...10800), // 1 min to 3 hours
            width: [1920, 3840].randomElement()!,
            height: [1080, 2160].randomElement()!,
            videoCodec: ["h264", "hevc", "prores"].randomElement()!,
            audioCodec: ["aac", "pcm_s16le"].randomElement()!,
            rotationDegrees: [0, 90, 180].randomElement()!,
            hdrMetadata: Bool.random() ? "HLG" : nil,
            estimatedOutputSize: Int64.random(in: 50_000_000...2_000_000_000),
            audioLayout: "stereo"
        )
    }

    public func run(
        _ job: JobRecord,
        preset: MediaPreset,
        progress: @Sendable @escaping (JobProgress) -> Void
    ) async throws -> JobOutput {
        let segmentCount = Int.random(in: 3...5)
        await logger.jobEvent(jobID: job.id, phase: .running, message: "Starting fake job with \(segmentCount) segments", fraction: 0)

        // Simulate segment-by-segment progress
        for i in 1...segmentCount {
            // Check for cancellation
            if isCancelled(jobID: job.id) {
                await logger.jobEvent(jobID: job.id, phase: .canceled, message: "Cancelled at segment \(i)/\(segmentCount)")
                progress(JobProgress(
                    phase: .canceled,
                    label: "Canceled after segment \(i) of \(segmentCount)",
                    fraction: Double(i - 1) / Double(segmentCount),
                    confidence: .measured
                ))
                throw CancellationError()
            }

            let fraction = Double(i) / Double(segmentCount)
            progress(JobProgress(
                phase: .running,
                label: "Processing segment \(i) of \(segmentCount)…",
                fraction: fraction,
                confidence: .measured,
                lastCheckpoint: "segment_\(i)"
            ))
            await logger.jobEvent(jobID: job.id, phase: .running, message: "Segment \(i)/\(segmentCount)", fraction: fraction)

            // Simulate work time (0.5–2s per segment, shorter for fake mode)
            try await Task.sleep(for: .milliseconds(Int.random(in: 300...800)))
        }

        // Validation phase
        progress(JobProgress(
            phase: .validating,
            label: "Verifying output…",
            fraction: 0.95,
            confidence: .validating
        ))
        try await Task.sleep(for: .milliseconds(500))

        let outputURL = OutputNaming.resolveOutputURL(for: job, preset: preset)
        let warnings: [String] = Bool.random() ? ["Audio layout could not be verified."] : []

        await logger.jobEvent(jobID: job.id, phase: .completed, message: "Done: \(outputURL.lastPathComponent)", fraction: 1.0)
        progress(JobProgress(phase: .completed, label: "Complete", fraction: 1.0, confidence: .measured))

        return JobOutput(
            url: outputURL,
            duration: 120.0,
            width: 1920,
            height: 1080,
            videoCodec: "h264",
            audioCodec: "aac",
            checksum: "sha256:\(UUID().uuidString)",
            warnings: warnings
        )
    }

    public func cancel(jobID: String) async {
        _ = lock.withLock { cancelledJobIDs.insert(jobID) }
        await logger.info("fake.engine", "Cancellation requested for job \(jobID.prefix(8))")
    }

    // MARK: - Private

    private func isCancelled(jobID: String) -> Bool {
        lock.withLock { cancelledJobIDs.contains(jobID) }
    }
}