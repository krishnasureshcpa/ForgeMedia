import Foundation
import ForgeMediaDomain
import os

/// Structured logger for ForgeMedia.
///
/// Logs are local-only by default; no telemetry or remote upload.
/// The ring buffer keeps the last N entries for in-app diagnostics display.
public actor DiagnosticsLogger {
    public static let shared = DiagnosticsLogger()

    private let logger = os.Logger(subsystem: "com.forgemedia.app", category: "diagnostics")
    private var ringBuffer: [LogEntry] = []
    private let maxRingBufferSize = 500

    // MARK: - Public API

    public func jobEvent(jobID: String, phase: JobPhase, message: String, fraction: Double? = nil) {
        let entry = LogEntry(
            level: .info,
            domain: "job.\(jobID.prefix(8))",
            message: "[\(phase.rawValue)] \(message)",
            fraction: fraction
        )
        append(entry)
        logger.info("[\(entry.domain)] \(entry.message, privacy: .public)")
    }

    public func info(_ domain: String, _ message: String) {
        let entry = LogEntry(level: .info, domain: domain, message: message)
        append(entry)
        logger.info("[\(domain)] \(message, privacy: .public)")
    }

    public func warning(_ domain: String, _ message: String) {
        let entry = LogEntry(level: .warning, domain: domain, message: message)
        append(entry)
        logger.warning("[\(domain)] \(message, privacy: .public)")
    }

    public func error(_ domain: String, _ message: String) {
        let entry = LogEntry(level: .error, domain: domain, message: message)
        append(entry)
        logger.error("[\(domain)] \(message, privacy: .public)")
    }

    /// Returns recent log entries for display in the diagnostics panel.
    public func recentEntries(limit: Int = 100) -> [LogEntry] {
        Array(ringBuffer.suffix(limit))
    }

    /// Clear the in-memory ring buffer (persisted logs are unaffected).
    public func clearBuffer() {
        ringBuffer.removeAll()
    }

    // MARK: - Private

    private func append(_ entry: LogEntry) {
        ringBuffer.append(entry)
        if ringBuffer.count > maxRingBufferSize {
            ringBuffer.removeFirst(ringBuffer.count - maxRingBufferSize)
        }
    }
}

// MARK: - Log entry

public struct LogEntry: Sendable, Identifiable {
    public let id = UUID()
    public let timestamp: Date
    public let level: LogLevel
    public let domain: String
    public let message: String
    public let fraction: Double?

    init(level: LogLevel, domain: String, message: String, fraction: Double? = nil) {
        self.timestamp = Date()
        self.level = level
        self.domain = domain
        self.message = message
        self.fraction = fraction
    }
}

public enum LogLevel: String, Sendable, CaseIterable {
    case info
    case warning
    case error
}