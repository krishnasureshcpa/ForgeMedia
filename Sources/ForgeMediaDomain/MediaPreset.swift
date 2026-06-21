import Foundation

/// A user-defined or built-in processing preset.
public struct MediaPreset: Codable, Sendable, Identifiable, Equatable {
    public var id: String
    public var name: String
    public var engine: String          // "avfoundation", "ffmpeg", "whisper", or custom
    public var outputContainer: String // "mp4", "mov", "srt", "vtt", "json"
    public var videoCodec: String?     // nil if audio-only
    public var audioCodec: String?
    public var subtitleBehavior: String // "burn", "sidecar", "none"
    public var privacyMode: PrivacyMode

    public init(
        id: String,
        name: String,
        engine: String,
        outputContainer: String,
        videoCodec: String? = nil,
        audioCodec: String? = nil,
        subtitleBehavior: String = "none",
        privacyMode: PrivacyMode = .privacyOn
    ) {
        self.id = id
        self.name = name
        self.engine = engine
        self.outputContainer = outputContainer
        self.videoCodec = videoCodec
        self.audioCodec = audioCodec
        self.subtitleBehavior = subtitleBehavior
        self.privacyMode = privacyMode
    }
}

// MARK: - Built-in presets

public extension MediaPreset {
    static let builtIn: [MediaPreset] = [
        // ── Convert ──
        .init(id: "convert_h264",       name: "Convert to H.264",       engine: "ffmpeg",         outputContainer: "mp4", videoCodec: "h264",              audioCodec: "aac"),
        .init(id: "convert_hevc",       name: "Convert to HEVC",        engine: "ffmpeg",         outputContainer: "mp4", videoCodec: "hevc_videotoolbox",  audioCodec: "aac"),
        .init(id: "stitch",             name: "Stitch Clips",           engine: "avfoundation",   outputContainer: "mp4"),
        .init(id: "merge_audio",        name: "Merge Audio Tracks",     engine: "avfoundation",   outputContainer: "mp4", audioCodec: "aac"),

        // ── Transcription / AI ──
        .init(id: "transcribe",         name: "Transcribe",             engine: "whisper",        outputContainer: "srt",  videoCodec: nil, audioCodec: nil, subtitleBehavior: "sidecar"),
        .init(id: "transcribe_translate",name: "Transcribe + Translate → EN", engine: "pipeline_transcribe", outputContainer: "srt", videoCodec: nil, audioCodec: nil, subtitleBehavior: "sidecar"),
        .init(id: "dub_translate_en",   name: "Dub + Lip-Sync to English", engine: "open_dubbing", outputContainer: "mp4", videoCodec: "h264", audioCodec: "aac", subtitleBehavior: "burn"),

        // ── Restoration (real pipeline) ──
        // pipeline_clean   → stabilize + denoise via ffmpeg deshake + hqdn3d
        // pipeline_4k      → stabilize + denoise + MetalFX upscale to 4K
        // pipeline_realesrgan → stabilize + denoise + Real-ESRGAN per-frame ML upscale (slow)
        .init(id: "restore_clean",      name: "Restore: Stabilize + Denoise",     engine: "pipeline_clean",       outputContainer: "mp4", videoCodec: "hevc_videotoolbox", audioCodec: "aac"),
        .init(id: "restore_4k",         name: "Restore: Clean + Upscale 4K",      engine: "pipeline_4k",          outputContainer: "mp4", videoCodec: "hevc_videotoolbox", audioCodec: "aac"),
        .init(id: "restore_4k_ml",      name: "Restore: Clean + Real-ESRGAN 4K",  engine: "pipeline_realesrgan",  outputContainer: "mp4", videoCodec: "hevc_videotoolbox", audioCodec: "aac"),
    ]
}
