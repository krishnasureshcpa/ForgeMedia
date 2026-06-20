import Foundation

/// Result of probing a media file.
public struct MediaProbeResult: Sendable, Equatable {
    public var duration: TimeInterval?
    public var width: Int?
    public var height: Int?
    public var videoCodec: String?
    public var audioCodec: String?
    public var rotationDegrees: Int?
    public var hdrMetadata: String?
    public var estimatedOutputSize: Int64?
    public var audioLayout: String?

    public init(
        duration: TimeInterval? = nil,
        width: Int? = nil,
        height: Int? = nil,
        videoCodec: String? = nil,
        audioCodec: String? = nil,
        rotationDegrees: Int? = nil,
        hdrMetadata: String? = nil,
        estimatedOutputSize: Int64? = nil,
        audioLayout: String? = nil
    ) {
        self.duration = duration
        self.width = width
        self.height = height
        self.videoCodec = videoCodec
        self.audioCodec = audioCodec
        self.rotationDegrees = rotationDegrees
        self.hdrMetadata = hdrMetadata
        self.estimatedOutputSize = estimatedOutputSize
        self.audioLayout = audioLayout
    }

    /// Human-readable summary for UI display.
    public var summary: String {
        var parts: [String] = []
        if let d = duration { parts.append("Duration: \(formatDuration(d))") }
        if let w = width, let h = height { parts.append("\(w)×\(h)") }
        if let v = videoCodec { parts.append("Video: \(v)") }
        if let a = audioCodec { parts.append("Audio: \(a)") }
        if let rot = rotationDegrees, rot != 0 { parts.append("Rotation: \(rot)°") }
        return parts.joined(separator: " · ")
    }

    private func formatDuration(_ d: TimeInterval) -> String {
        let h = Int(d) / 3600
        let m = (Int(d) % 3600) / 60
        let s = Int(d) % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }
}