import Foundation

/// The 10 canonical job lifecycle states.
///
/// Every user-facing surface must handle every state in this enum.
public enum JobPhase: String, Codable, Sendable, CaseIterable {
    case idle
    case preparing
    case probing
    case planning
    case separating   // Demucs stem separation
    case transcribing // Whisper speech-to-text (+ translate)
    case stabilizing  // FFmpeg deshake + denoise
    case running
    case validating
    case paused
    case takingLonger
    case completed
    case completedWithWarnings
    case failed
    case canceled
    case recovered
}