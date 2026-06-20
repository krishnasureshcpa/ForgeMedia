/// Progress confidence tracks how the progressFraction was derived.
///
///  unknown    — Engine cannot report progress yet; prefer a labelled spinner.
///  estimated  — Based on file size, segment count, or historical timings.
///  measured   — Based on completed segments, byte ranges, or engine output.
///  validating — Work is complete; output quality checks are still running.
public enum ProgressConfidence: String, Codable, Sendable, CaseIterable {
    case unknown
    case estimated
    case measured
    case validating
}