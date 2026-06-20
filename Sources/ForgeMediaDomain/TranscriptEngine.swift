import Foundation

// MARK: - Transcript engine protocol

public protocol TranscriptEngine: Sendable {
    func transcribe(
        mediaURL: URL,
        model: WhisperModelDescriptor,
        progress: @Sendable @escaping (TranscriptProgress) -> Void
    ) async throws -> TranscriptOutput
}

// MARK: - Whisper model descriptor

public struct WhisperModelDescriptor: Sendable, Equatable {
    public var name: String
    public var quantization: String
    public var source: String
    public var license: String
    public var acceleration: WhisperAccelerationMode

    public init(
        name: String,
        quantization: String,
        source: String,
        license: String,
        acceleration: WhisperAccelerationMode = .cpu
    ) {
        self.name = name
        self.quantization = quantization
        self.source = source
        self.license = license
        self.acceleration = acceleration
    }
}

public enum WhisperAccelerationMode: String, Sendable, CaseIterable {
    case cpu
    case metal
    case coreML
    case coreMLWithANEFallback
}

// MARK: - Transcript progress

public struct TranscriptProgress: Sendable, Equatable {
    public var segmentIndex: Int
    public var segmentCount: Int
    public var label: String
    public var fraction: Double

    public init(segmentIndex: Int, segmentCount: Int, label: String, fraction: Double) {
        self.segmentIndex = segmentIndex
        self.segmentCount = segmentCount
        self.label = label
        self.fraction = fraction
    }
}

// MARK: - Transcript output

public struct TranscriptOutput: Sendable, Equatable {
    public var url: URL
    public var format: TranscriptFormat
    public var language: String?
    public var wordTimings: Bool

    public init(url: URL, format: TranscriptFormat, language: String? = nil, wordTimings: Bool = false) {
        self.url = url
        self.format = format
        self.language = language
        self.wordTimings = wordTimings
    }
}

public enum TranscriptFormat: String, Sendable, CaseIterable {
    case srt
    case vtt
    case json
}