import Foundation

/// Protocol for the media processing engine.
///
/// Implementations include FakeProcessingEngine (for UI dev), FFmpegProcessRunner,
/// and AVFoundationComposer. The engine runs in a background worker — the UI only
/// receives progress events and final output.
public protocol ProcessingEngine: Sendable {
    /// Probe a file to determine its media properties.
    func probe(_ url: URL) async throws -> MediaProbeResult

    /// Run a processing job, calling `progress` as the job advances.
    func run(
        _ job: JobRecord,
        preset: MediaPreset,
        progress: @Sendable @escaping (JobProgress) -> Void
    ) async throws -> JobOutput

    /// Request cancellation of a running job. Best-effort; the engine should
    /// clean up temporary files and emit a .canceled phase through the progress
    /// callback before throwing `CancellationError`.
    func cancel(jobID: String) async
}