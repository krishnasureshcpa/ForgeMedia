import Foundation
import ForgeMediaDomain
import ForgeMediaDiagnostics

/// Processing engine that delegates dubbing workflow to the local Python batch pipeline.
public final class OpenDubbingBatchEngine: ProcessingEngine, @unchecked Sendable {
    private let logger = DiagnosticsLogger.shared
    private let processLock = NSLock()
    private var activeProcesses: [String: Process] = [:]

    public init() {}

    public func probe(_ url: URL) async throws -> MediaProbeResult {
        MediaProbeResult(
            duration: nil,
            width: nil,
            height: nil,
            videoCodec: nil,
            audioCodec: nil,
            rotationDegrees: 0,
            hdrMetadata: nil,
            estimatedOutputSize: nil,
            audioLayout: nil
        )
    }

    public func run(
        _ job: JobRecord,
        preset: MediaPreset,
        progress: @Sendable @escaping (JobProgress) -> Void
    ) async throws -> JobOutput {
        let sourcePath = job.sourceURL.path
        let sourceURL = URL(fileURLWithPath: sourcePath)
        let sourceRoot = sourceURL.deletingLastPathComponent().path
        let destinationRoot = sourceURL.deletingLastPathComponent().appendingPathComponent("ForgeMedia-processed").path

        let repoRoot = FileManager.default.currentDirectoryPath
        let scriptPath = URL(fileURLWithPath: repoRoot)
            .appendingPathComponent("scripts")
            .appendingPathComponent("video-batch-pipeline")
            .appendingPathComponent("batch_pipeline.py")
            .path

        progress(JobProgress(phase: .preparing, label: "Preparing local dubbing pipeline…", fraction: 0.05, confidence: .estimated))

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [
            "python3",
            scriptPath,
            "--source", sourceRoot,
            "--destination", destinationRoot,
            "--single-file", sourcePath,
            "--target-language", "en",
            "--lip-sync-tool", "musetalk",
            "--whisper-model", "medium",
            "--quality-profile", "fast"
        ]

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        processLock.withLock { activeProcesses[job.id] = process }
        defer { _ = processLock.withLock { activeProcesses.removeValue(forKey: job.id) } }

        try process.run()

        let stderrTask = Task {
            for try await line in stderrPipe.fileHandleForReading.bytes.lines {
                await self.logger.info("open-dubbing", line)
            }
        }

        let progressTask = Task {
            var stepsCompleted = 0.0
            for try await line in stdoutPipe.fileHandleForReading.bytes.lines {
                await self.logger.info("open-dubbing", line)
                if line.contains("[STEP]") {
                    stepsCompleted += 1.0
                    let fraction = min(0.1 + stepsCompleted * 0.2, 0.9)
                    progress(JobProgress(phase: .running, label: line.replacingOccurrences(of: "[STEP] ", with: ""), fraction: fraction, confidence: .estimated))
                } else if line.contains("[DONE]") {
                    progress(JobProgress(phase: .validating, label: "Finalizing dubbed output…", fraction: 0.95, confidence: .validating))
                } else if line.contains("[FILE]") {
                    progress(JobProgress(phase: .running, label: line.replacingOccurrences(of: "[FILE] ", with: ""), fraction: 0.08, confidence: .estimated))
                }
            }
        }

        let heartbeatTask = Task {
            var tick = 0
            while process.isRunning {
                try? await Task.sleep(for: .seconds(2))
                tick += 1
                if tick % 3 == 0 {
                    progress(JobProgress(
                        phase: .running,
                        label: "Pipeline running… \(tick * 2)s elapsed",
                        fraction: min(0.1 + Double(tick) * 0.01, 0.9),
                        confidence: .estimated
                    ))
                }
            }
        }

        process.waitUntilExit()
        progressTask.cancel()
        stderrTask.cancel()
        heartbeatTask.cancel()

        guard process.terminationStatus == 0 else {
            throw OpenDubbingEngineError.pipelineFailed(code: process.terminationStatus)
        }

        let outputURL = URL(fileURLWithPath: destinationRoot)
            .appendingPathComponent(sourceURL.lastPathComponent)
            .deletingPathExtension()
            .appendingPathExtension("mp4")

        progress(JobProgress(phase: .completed, label: "Complete", fraction: 1.0, confidence: .measured))
        return JobOutput(url: outputURL, warnings: [])
    }

    public func cancel(jobID: String) async {
        let process = processLock.withLock { activeProcesses[jobID] }
        process?.interrupt()
        process?.terminate()
    }
}

public enum OpenDubbingEngineError: LocalizedError {
    case pipelineFailed(code: Int32)

    public var errorDescription: String? {
        switch self {
        case .pipelineFailed(let code):
            return "Open dubbing batch pipeline failed with exit code \(code)"
        }
    }
}
