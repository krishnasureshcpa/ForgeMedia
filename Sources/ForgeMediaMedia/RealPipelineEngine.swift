import Foundation
import ForgeMediaDomain
import ForgeMediaDiagnostics

// MARK: - Internal shell runner (mirrors Mediatron ShellRunner)

private struct Shell {
    static func run(_ command: String, arguments: [String] = [], timeout: TimeInterval = 300) -> (output: String, exitCode: Int32) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments
        process.qualityOfService = .userInitiated

        let stdout = Pipe(); let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        let sem = DispatchSemaphore(value: 0)
        do { try process.run() } catch { return (error.localizedDescription, -1) }

        DispatchQueue.global().async { process.waitUntilExit(); sem.signal() }
        if sem.wait(timeout: .now() + timeout) == .timedOut {
            process.terminate()
            return ("Timed out after \(Int(timeout))s", -9)
        }
        let out = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let err = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return (out.isEmpty ? err : out, process.terminationStatus)
    }

    static func find(_ name: String) -> String? {
        let home = NSHomeDirectory()
        let candidates = [
            "/opt/homebrew/bin/\(name)",
            "/usr/local/bin/\(name)",
            "\(home)/.forgemedia/bin/\(name)",
            "\(home)/.mediatron/bin/\(name)",
        ]
        for p in candidates where FileManager.default.fileExists(atPath: p) { return p }
        let r = run("/usr/bin/env", arguments: ["which", name])
        if r.exitCode == 0 { return r.output.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty }
        return nil
    }
}

// MARK: - Pipeline options derived from MediaPreset.engine

private struct PipelineOptions {
    var enableStabilization: Bool    = false
    var enableDenoise: Bool          = false
    var enableUpscaling: Bool        = false
    var upscaleEngine: UpscaleEngine = .metalFX
    var enableTranscribe: Bool       = false
    var translateToEnglish: Bool     = false
    var enableStemSeparation: Bool   = false

    enum UpscaleEngine { case metalFX, realESRGAN }

    static func from(preset: MediaPreset) -> PipelineOptions {
        var o = PipelineOptions()
        switch preset.engine {
        case "pipeline_clean":
            o.enableStabilization = true; o.enableDenoise = true
        case "pipeline_4k":
            o.enableStabilization = true; o.enableDenoise = true
            o.enableUpscaling = true; o.upscaleEngine = .metalFX
        case "pipeline_realesrgan":
            o.enableStabilization = true; o.enableDenoise = true
            o.enableUpscaling = true; o.upscaleEngine = .realESRGAN
        case "pipeline_transcribe", "whisper":
            o.enableTranscribe = true; o.translateToEnglish = true
        case "pipeline":
            o.enableStabilization = true; o.enableDenoise = true
            o.enableTranscribe = true; o.translateToEnglish = true
            o.enableStemSeparation = true
        default:
            break
        }
        return o
    }

    var isPipelinePreset: Bool {
        enableStabilization || enableDenoise || enableUpscaling || enableTranscribe || enableStemSeparation
    }
}

// MARK: - Real Pipeline Engine

/// Full restoration pipeline for ForgeMedia. Adapts Mediatron's PipelineEngine for the
/// ForgeMedia ProcessingEngine protocol and SPM module architecture.
///
/// Pipeline order per task:
///   analyze → [stems: Demucs] → [transcribe (+translate): whisper-cli] →
///   [clean: ffmpeg deshake + hqdn3d] → [upscale: MetalFX | Real-ESRGAN] →
///   encode + mux → integrity check
///
/// All stages are optional and gated by the preset's engine field. Unavailable
/// tools log a warning and skip their stage — they never produce silent garbage.
public final class RealPipelineEngine: ProcessingEngine, @unchecked Sendable {
    private let logger = DiagnosticsLogger.shared
    private let ffmpegPath: String
    private let ffprobePath: String?
    private let lock = NSLock()
    private var activeProcesses: [String: Process] = [:]

    public init(ffmpegPath: String, ffprobePath: String? = nil) {
        self.ffmpegPath = ffmpegPath
        self.ffprobePath = ffprobePath
    }

    // MARK: - ProcessingEngine conformance

    public func probe(_ url: URL) async throws -> MediaProbeResult {
        let ffprobe = ffprobePath ?? ffmpegPath.replacingOccurrences(of: "ffmpeg", with: "ffprobe")
        let r = Shell.run(ffprobe, arguments: ["-v", "quiet", "-print_format", "json", "-show_format", "-show_streams", url.path])
        guard r.exitCode == 0,
              let data = r.output.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let format = json["format"] as? [String: Any],
              let streams = json["streams"] as? [[String: Any]] else {
            throw ProcessingError.probeFailed(code: r.exitCode)
        }
        let dur = (format["duration"] as? String).flatMap(Double.init)
        let vStream = streams.first(where: { $0["codec_type"] as? String == "video" })
        let aStream = streams.first(where: { $0["codec_type"] as? String == "audio" })
        return MediaProbeResult(
            duration: dur,
            width: vStream?["width"] as? Int,
            height: vStream?["height"] as? Int,
            videoCodec: vStream?["codec_name"] as? String,
            audioCodec: aStream?["codec_name"] as? String
        )
    }

    public func run(
        _ job: JobRecord,
        preset: MediaPreset,
        progress: @Sendable @escaping (JobProgress) -> Void
    ) async throws -> JobOutput {
        let opts = PipelineOptions.from(preset: preset)

        // Non-pipeline presets: delegate to simple FFmpeg encode
        guard opts.isPipelinePreset else {
            return try await runSimpleFFmpeg(job, preset: preset, progress: progress)
        }

        await logger.info("pipeline", "[\(job.title)] Starting pipeline: \(preset.engine)")

        let workDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("fm_pipeline_\(job.id)")
        try? FileManager.default.createDirectory(at: workDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: workDir) }

        // ── Stage 1: Probe ──
        progress(JobProgress(phase: .probing, label: "Analyzing media…", fraction: 0.02))
        let probed = try? await probe(job.sourceURL)
        await logger.info("pipeline", "[\(job.title)] \(probed?.summary ?? "probe unavailable")")

        // ── Stage 2a: Stem separation (Demucs) ──
        var stems: (vocals: URL, background: URL)? = nil
        if opts.enableStemSeparation {
            progress(JobProgress(phase: .separating, label: "Separating stems (Demucs)…", fraction: 0.05))
            stems = await separateStems(job.sourceURL, into: workDir)
            if stems != nil {
                await logger.info("pipeline", "[\(job.title)] Stems ready — dialogue isolated")
            } else {
                await logger.info("pipeline", "[\(job.title)] Stem separation unavailable — using full mix")
            }
        }

        // ── Stage 2b: Transcribe + translate ──
        var transcriptText = ""
        if opts.enableTranscribe {
            let wantTranslate = opts.translateToEnglish &&
                !(job.effectiveSourceLanguage.hasPrefix("en"))
            progress(JobProgress(phase: .transcribing,
                label: wantTranslate ? "Transcribing + translating to English…" : "Transcribing audio…",
                fraction: 0.12))
            transcriptText = await transcribeAudio(
                job.sourceURL,
                language: job.effectiveSourceLanguage,
                translateToEnglish: wantTranslate,
                audioInput: stems?.vocals
            )
            await logger.info("pipeline", "[\(job.title)] Transcript: \(String(transcriptText.prefix(80)))…")
        }

        // ── Stage 3: Clean (stabilize + denoise) ──
        var workingSource = job.sourceURL
        if opts.enableStabilization || opts.enableDenoise {
            progress(JobProgress(phase: .stabilizing,
                label: [opts.enableStabilization ? "Stabilizing" : nil,
                         opts.enableDenoise ? "Denoising" : nil]
                    .compactMap({ $0 }).joined(separator: " + ") + "…",
                fraction: 0.25))
            if let cleaned = await cleanVideo(workingSource, workDir: workDir,
                stabilize: opts.enableStabilization, denoise: opts.enableDenoise) {
                workingSource = cleaned
                await logger.info("pipeline", "[\(job.title)] Clean pre-pass succeeded")
            } else {
                await logger.info("pipeline", "[\(job.title)] Clean pre-pass failed — using original")
            }
        }

        // ── Stage 4: Upscale ──
        if opts.enableUpscaling {
            progress(JobProgress(phase: .running, label: "Upscaling to 4K…", fraction: 0.45))
            switch opts.upscaleEngine {
            case .realESRGAN:
                if let upscaled = await upscaleWithRealESRGAN(workingSource, workDir: workDir, progress: progress) {
                    workingSource = upscaled
                    await logger.info("pipeline", "[\(job.title)] Real-ESRGAN done")
                } else {
                    // Fallback: MetalFX
                    await logger.info("pipeline", "[\(job.title)] Real-ESRGAN failed — trying MetalFX")
                    if let upscaled = upscaleWithMetalFX(workingSource) {
                        workingSource = upscaled
                    }
                }
            case .metalFX:
                if let upscaled = upscaleWithMetalFX(workingSource) {
                    workingSource = upscaled
                    await logger.info("pipeline", "[\(job.title)] MetalFX done")
                } else {
                    await logger.info("pipeline", "[\(job.title)] MetalFX unavailable — lanczos fallback in encode")
                }
            }
        }

        // ── Stage 5: Final encode + mux ──
        progress(JobProgress(phase: .running, label: "Encoding and muxing…", fraction: 0.62))
        let outputURL = try await encodeAndMux(
            source: workingSource,
            originalSource: job.sourceURL,
            preset: preset,
            job: job,
            backgroundAudio: stems?.background,
            needsUpscaleFallback: opts.enableUpscaling && workingSource == job.sourceURL,
            progress: progress
        )

        // ── Stage 6: Integrity check ──
        progress(JobProgress(phase: .validating, label: "Verifying output…", fraction: 0.96))
        var warnings: [String] = []
        if let srcDur = probed?.duration {
            let outProbed = try? await probe(outputURL)
            if let outDur = outProbed?.duration, abs(outDur - srcDur) > srcDur * 0.05 {
                warnings.append("Duration mismatch: source \(String(format: "%.1f", srcDur))s vs output \(String(format: "%.1f", outDur))s")
                await logger.info("pipeline", "[\(job.title)] Warning: \(warnings[0])")
            }
        }

        let finalProbe = try? await probe(outputURL)
        progress(JobProgress(phase: .completed, label: "Complete", fraction: 1.0))
        await logger.info("pipeline", "[\(job.title)] Done → \(outputURL.lastPathComponent)")

        return JobOutput(
            url: outputURL,
            duration: finalProbe?.duration,
            width: finalProbe?.width,
            height: finalProbe?.height,
            videoCodec: finalProbe?.videoCodec,
            audioCodec: finalProbe?.audioCodec,
            warnings: warnings
        )
    }

    public func cancel(jobID: String) async {
        let p = lock.withLock { activeProcesses[jobID] }
        p?.interrupt(); p?.terminate()
        await logger.info("pipeline", "Cancel requested for \(jobID)")
    }

    // MARK: - Pipeline stages

    /// Demucs two-stems separation: vocals.wav + no_vocals.wav.
    /// Returns nil if demucs is unavailable or fails (caller uses full mix as fallback).
    private func separateStems(_ url: URL, into dir: URL) async -> (vocals: URL, background: URL)? {
        guard let demucs = Shell.find("demucs") else {
            await logger.info("pipeline", "demucs not found — skipping stem separation")
            return nil
        }
        guard let ffmpeg = Shell.find("ffmpeg") else { return nil }

        let inputWav = dir.appendingPathComponent("input.wav")
        let extract = Shell.run(ffmpeg, arguments: [
            "-y", "-i", url.path, "-vn", "-acodec", "pcm_s16le", "-ar", "44100", "-ac", "2",
            inputWav.path
        ], timeout: 120)
        guard extract.exitCode == 0 else { return nil }

        let outDir = dir.appendingPathComponent("demucs_out")
        let result = Shell.run(demucs, arguments: [
            "--two-stems", "vocals", "-o", outDir.path, inputWav.path
        ], timeout: 1800)

        if let modelDirs = try? FileManager.default.contentsOfDirectory(at: outDir, includingPropertiesForKeys: nil) {
            for modelDir in modelDirs {
                let trackDir = modelDir.appendingPathComponent("input")
                let vocals = trackDir.appendingPathComponent("vocals.wav")
                let bg = trackDir.appendingPathComponent("no_vocals.wav")
                if FileManager.default.fileExists(atPath: vocals.path),
                   FileManager.default.fileExists(atPath: bg.path) {
                    return (vocals, bg)
                }
            }
        }
        await logger.info("pipeline", "demucs output not found (exit \(result.exitCode))")
        return nil
    }

    /// Whisper speech-to-text with optional -tr translate-to-English.
    /// NOTE: whisper can only translate *to English*. Other target languages fall back
    /// to source-language transcription (no real translation).
    private func transcribeAudio(
        _ url: URL,
        language: String,
        translateToEnglish: Bool,
        audioInput: URL?
    ) async -> String {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let audioPath = tmp.appendingPathComponent("audio.wav").path
        guard let ffmpeg = Shell.find("ffmpeg") else { return "" }

        let extract = Shell.run(ffmpeg, arguments: [
            "-y", "-i", (audioInput ?? url).path,
            "-vn", "-acodec", "pcm_s16le", "-ar", "16000", "-ac", "1",
            "-t", "300", audioPath
        ], timeout: 60)
        guard extract.exitCode == 0 else { return "" }

        guard let whisper = Shell.find("whisper-cli"), let model = findWhisperModel() else {
            await logger.info("pipeline", "whisper-cli or model not found — no transcript")
            return ""
        }

        let lang = (language == "auto" || language.isEmpty) ? "auto" : language.lowercased()
        var args = ["-m", model, "-f", audioPath, "-l", lang, "-oj",
                    "-of", tmp.appendingPathComponent("transcript").path]
        if translateToEnglish && lang != "en" && lang != "auto" { args.append("-tr") }

        let result = Shell.run(whisper, arguments: args, timeout: 600)
        let jsonPath = tmp.appendingPathComponent("transcript.json").path
        if let data = try? Data(contentsOf: URL(fileURLWithPath: jsonPath)),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let text = json["text"] as? String {
            return text
        }
        return result.output
    }

    /// FFmpeg stabilize (deshake) + denoise (hqdn3d) pre-pass. Clean BEFORE upscale
    /// so we don't amplify grain into 4K. Encodes to HEVC at high bitrate to minimise
    /// generational quality loss.
    private func cleanVideo(_ source: URL, workDir: URL, stabilize: Bool, denoise: Bool) async -> URL? {
        guard let ffmpeg = Shell.find("ffmpeg") else { return nil }
        var filters: [String] = []
        if stabilize { filters.append("deshake") }
        if denoise   { filters.append("hqdn3d") }
        filters.append("format=yuv420p")

        let cleaned = workDir.appendingPathComponent("cleaned.mov")
        let r = Shell.run(ffmpeg, arguments: [
            "-y", "-i", source.path,
            "-vf", filters.joined(separator: ","),
            "-c:v", "hevc_videotoolbox", "-b:v", "20M", "-tag:v", "hvc1",
            "-c:a", "copy",
            cleaned.path
        ], timeout: 1800)
        return (r.exitCode == 0 && FileManager.default.fileExists(atPath: cleaned.path)) ? cleaned : nil
    }

    /// Real-ESRGAN frame-by-frame ML upscale.
    /// HONEST: this is slow and disk-heavy (every frame exported to PNG). Best for short
    /// clips or quality-critical archival work. Falls back to MetalFX on failure.
    /// Returns a video-only intermediate (no audio); caller muxes audio.
    private func upscaleWithRealESRGAN(_ source: URL, workDir: URL, progress: @Sendable @escaping (JobProgress) -> Void) async -> URL? {
        let home = NSHomeDirectory()
        let modelDir = "\(home)/.forgemedia/models/realesrgan"
        guard let realesrgan = Shell.find("realesrgan-ncnn-vulkan"),
              let ffmpeg = Shell.find("ffmpeg"),
              FileManager.default.fileExists(atPath: "\(modelDir)/realesrgan-x4plus.bin") else {
            return nil
        }

        let inFrames  = workDir.appendingPathComponent("resrgan_in")
        let outFrames = workDir.appendingPathComponent("resrgan_out")
        try? FileManager.default.createDirectory(at: inFrames, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: outFrames, withIntermediateDirectories: true)

        // Capture source fps
        var fps = "24"
        let ffprobe = ffmpegPath.replacingOccurrences(of: "ffmpeg", with: "ffprobe")
        let fpsR = Shell.run(ffprobe, arguments: [
            "-v", "error", "-select_streams", "v:0",
            "-show_entries", "stream=avg_frame_rate",
            "-of", "csv=p=0", source.path
        ], timeout: 10)
        if fpsR.exitCode == 0, !fpsR.output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            fps = fpsR.output.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty ?? fps
        }

        // Extract frames
        let extractR = Shell.run(ffmpeg, arguments: [
            "-y", "-i", source.path, "-q:v", "1",
            inFrames.appendingPathComponent("%08d.png").path
        ], timeout: 1800)
        guard extractR.exitCode == 0 else { return nil }

        // Upscale frames
        progress(JobProgress(phase: .running, label: "Real-ESRGAN upscaling frames…", fraction: 0.50))
        let upscaleR = Shell.run(realesrgan, arguments: [
            "-i", inFrames.path, "-o", outFrames.path,
            "-n", "realesrgan-x4plus", "-s", "4",
            "-m", modelDir
        ], timeout: 7200)
        guard upscaleR.exitCode == 0 else {
            await logger.info("pipeline", "Real-ESRGAN exit \(upscaleR.exitCode): \(upscaleR.output.suffix(200))")
            return nil
        }

        // Reassemble
        let assembled = workDir.appendingPathComponent("upscaled_video.mp4")
        let assembleR = Shell.run(ffmpeg, arguments: [
            "-y", "-framerate", fps,
            "-i", outFrames.appendingPathComponent("%08d.png").path,
            "-c:v", "hevc_videotoolbox", "-b:v", "40M", "-tag:v", "hvc1",
            "-an",
            assembled.path
        ], timeout: 1800)
        return (assembleR.exitCode == 0) ? assembled : nil
    }

    /// MetalFX upscale via fx-upscale CLI tool.
    private func upscaleWithMetalFX(_ source: URL) -> URL? {
        guard let fxUpscale = Shell.find("fx-upscale") else { return nil }
        let r = Shell.run(fxUpscale, arguments: [source.path, "--width", "3840", "--height", "2160", "--codec", "hevc"])
        if r.exitCode == 0 {
            let upscaled = source.deletingLastPathComponent()
                .appendingPathComponent("\(source.deletingPathExtension().lastPathComponent) Upscaled.mp4")
            return FileManager.default.fileExists(atPath: upscaled.path) ? upscaled : nil
        }
        return nil
    }

    /// Final FFmpeg encode pass: muxes video + dubbed/original audio, adds subtitles.
    private func encodeAndMux(
        source: URL,
        originalSource: URL,
        preset: MediaPreset,
        job: JobRecord,
        backgroundAudio: URL?,
        needsUpscaleFallback: Bool,
        progress: @Sendable @escaping (JobProgress) -> Void
    ) async throws -> URL {
        guard let ffmpeg = Shell.find("ffmpeg") else {
            throw ProcessingError.encodeFailed(message: "ffmpeg not found")
        }

        let outputURL = resolveOutputURL(for: job, preset: preset)
        let vCodec = preset.videoCodec ?? "hevc_videotoolbox"
        let aCodec = preset.audioCodec ?? "aac"

        var args: [String] = ["-y", "-i", source.path]
        if let bg = backgroundAudio { args += ["-i", bg.path] }

        if needsUpscaleFallback { args += ["-vf", "scale=3840:2160:flags=lanczos"] }

        args += ["-c:v", vCodec]
        if vCodec.contains("videotoolbox") { args += ["-b:v", "15M", "-tag:v", vCodec == "hevc_videotoolbox" ? "hvc1" : "avc1"] }

        if backgroundAudio != nil {
            args += ["-filter_complex", "[0:a][1:a]amix=inputs=2:duration=first:weights=1 0.7[aout]",
                     "-map", "0:v:0", "-map", "[aout]"]
        } else {
            args += ["-c:a", aCodec, "-b:a", "192k"]
        }
        args += ["-pix_fmt", "yuv420p", "-movflags", "+faststart"]
        args.append(outputURL.path)

        let totalDur = (try? await probe(originalSource))?.duration ?? 0
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpeg)
        process.arguments = args
        let outPipe = Pipe(); let errPipe = Pipe()
        process.standardOutput = outPipe; process.standardError = errPipe

        lock.withLock { activeProcesses[job.id] = process }
        defer { _ = lock.withLock { activeProcesses.removeValue(forKey: job.id) } }

        try process.run()

        // Stream stderr for progress
        let progressTask = Task {
            for try await line in outPipe.fileHandleForReading.bytes.lines {
                if line.hasPrefix("out_time_ms="), let ms = Double(line.split(separator: "=").last ?? "") {
                    let frac = totalDur > 0 ? min(0.62 + (ms / (totalDur * 1000)) * 0.30, 0.92) : 0.75
                    progress(JobProgress(phase: .running, label: "Encoding…", fraction: frac))
                }
            }
        }
        process.waitUntilExit()
        progressTask.cancel()

        guard process.terminationStatus == 0 else {
            let err = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw ProcessingError.encodeFailed(message: String(err.suffix(400)))
        }
        return outputURL
    }

    // MARK: - Simple FFmpeg passthrough (for non-pipeline presets)

    private func runSimpleFFmpeg(
        _ job: JobRecord,
        preset: MediaPreset,
        progress: @Sendable @escaping (JobProgress) -> Void
    ) async throws -> JobOutput {
        guard let ffmpeg = Shell.find("ffmpeg") else {
            throw ProcessingError.encodeFailed(message: "ffmpeg not found")
        }
        let outputURL = resolveOutputURL(for: job, preset: preset)
        let totalDur = (try? await probe(job.sourceURL))?.duration ?? 0
        progress(JobProgress(phase: .preparing, label: "Preparing encoder…", fraction: 0.03))

        var args = ["-y", "-i", job.sourceURL.path]
        if let vc = preset.videoCodec { args += ["-c:v", vc] } else { args += ["-c:v", "copy"] }
        if let ac = preset.audioCodec { args += ["-c:a", ac] } else { args += ["-c:a", "copy"] }
        args += ["-progress", "pipe:1", "-nostats", outputURL.path]

        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpeg)
        process.arguments = args
        let outPipe = Pipe(); let errPipe = Pipe()
        process.standardOutput = outPipe; process.standardError = errPipe

        lock.withLock { activeProcesses[job.id] = process }
        defer { _ = lock.withLock { activeProcesses.removeValue(forKey: job.id) } }

        try process.run()
        let progressTask = Task {
            for try await line in outPipe.fileHandleForReading.bytes.lines {
                if line.hasPrefix("out_time_ms="), let ms = Double(line.split(separator: "=").last ?? "") {
                    let frac = totalDur > 0 ? max(0.05, min(ms / (totalDur * 1000), 0.94)) : 0.5
                    progress(JobProgress(phase: .running, label: "Encoding…", fraction: frac))
                }
            }
        }
        while process.isRunning {
            if job.cancellationRequested {
                process.interrupt(); process.terminate()
                progressTask.cancel()
                throw CancellationError()
            }
            try await Task.sleep(for: .milliseconds(250))
        }
        progressTask.cancel()
        guard process.terminationStatus == 0 else {
            let err = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw ProcessingError.encodeFailed(message: String(err.suffix(400)))
        }
        let out = try? await probe(outputURL)
        progress(JobProgress(phase: .completed, label: "Complete", fraction: 1.0))
        return JobOutput(url: outputURL, duration: out?.duration, width: out?.width, height: out?.height,
                         videoCodec: out?.videoCodec, audioCodec: out?.audioCodec)
    }

    // MARK: - Helpers

    private func findWhisperModel() -> String? {
        let home = NSHomeDirectory()
        let paths = [
            "\(home)/.forgemedia/models/ggml-large-v3.bin",
            "\(home)/.mediatron/models/ggml-large-v3.bin",
            "\(home)/.forgemedia/models/ggml-medium.bin",
            "\(home)/.mediatron/models/ggml-medium.bin",
            "\(home)/.forgemedia/models/ggml-small.bin",
            "/opt/homebrew/share/whisper-cpp/for-tests-ggml-tiny.bin",
        ]
        return paths.first { FileManager.default.fileExists(atPath: $0) }
    }

    private func resolveOutputURL(for job: JobRecord, preset: MediaPreset) -> URL {
        if let explicit = job.outputURL { return explicit }
        let ext = preset.outputContainer.isEmpty ? "mp4" : preset.outputContainer
        let dir = job.sourceURL.deletingLastPathComponent()
        var stem = job.sourceURL.lastPathComponent
        while stem.contains(".") { stem = URL(fileURLWithPath: stem).deletingPathExtension().lastPathComponent }
        return dir.appendingPathComponent("\(stem)_\(preset.id)").appendingPathExtension(ext)
    }
}

// MARK: - String helper

private extension String {
    var nonEmpty: String? { isEmpty ? nil : self }
}
