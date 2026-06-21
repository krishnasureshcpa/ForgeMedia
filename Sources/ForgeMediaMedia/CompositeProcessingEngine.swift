import Foundation
import ForgeMediaDomain

/// Routes jobs to specialized engines based on preset metadata.
public final class CompositeProcessingEngine: ProcessingEngine, @unchecked Sendable {
    private let defaultEngine: ProcessingEngine
    private let openDubbingEngine: ProcessingEngine
    private let pipelineEngine: ProcessingEngine?

    public init(
        defaultEngine: ProcessingEngine,
        openDubbingEngine: ProcessingEngine,
        pipelineEngine: ProcessingEngine? = nil
    ) {
        self.defaultEngine = defaultEngine
        self.openDubbingEngine = openDubbingEngine
        self.pipelineEngine = pipelineEngine
    }

    public func probe(_ url: URL) async throws -> MediaProbeResult {
        try await defaultEngine.probe(url)
    }

    public func run(
        _ job: JobRecord,
        preset: MediaPreset,
        progress: @Sendable @escaping (JobProgress) -> Void
    ) async throws -> JobOutput {
        if preset.engine == "open_dubbing" {
            return try await openDubbingEngine.run(job, preset: preset, progress: progress)
        }
        if preset.engine.hasPrefix("pipeline_") || preset.engine == "pipeline",
           let pipeline = pipelineEngine {
            return try await pipeline.run(job, preset: preset, progress: progress)
        }
        return try await defaultEngine.run(job, preset: preset, progress: progress)
    }

    public func cancel(jobID: String) async {
        await defaultEngine.cancel(jobID: jobID)
        await openDubbingEngine.cancel(jobID: jobID)
        await pipelineEngine?.cancel(jobID: jobID)
    }
}
