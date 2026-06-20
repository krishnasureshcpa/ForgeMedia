import Foundation

/// Progress update emitted by a running engine.
public struct JobProgress: Sendable, Equatable {
    public var phase: JobPhase
    public var label: String
    public var fraction: Double
    public var confidence: ProgressConfidence
    public var lastCheckpoint: String?

    public init(
        phase: JobPhase,
        label: String,
        fraction: Double,
        confidence: ProgressConfidence = .measured,
        lastCheckpoint: String? = nil
    ) {
        self.phase = phase
        self.label = label
        self.fraction = fraction
        self.confidence = confidence
        self.lastCheckpoint = lastCheckpoint
    }
}

/// Output produced by a completed processing job.
public struct JobOutput: Sendable, Equatable {
    public var url: URL
    public var duration: TimeInterval?
    public var width: Int?
    public var height: Int?
    public var videoCodec: String?
    public var audioCodec: String?
    public var checksum: String?
    public var warnings: [String]

    public init(
        url: URL,
        duration: TimeInterval? = nil,
        width: Int? = nil,
        height: Int? = nil,
        videoCodec: String? = nil,
        audioCodec: String? = nil,
        checksum: String? = nil,
        warnings: [String] = []
    ) {
        self.url = url
        self.duration = duration
        self.width = width
        self.height = height
        self.videoCodec = videoCodec
        self.audioCodec = audioCodec
        self.checksum = checksum
        self.warnings = warnings
    }
}