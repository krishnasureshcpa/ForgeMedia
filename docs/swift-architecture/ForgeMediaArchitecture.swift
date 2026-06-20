import Foundation
import GRDB

// ForgeMedia architecture scaffold.
// This file is intentionally protocol-first so the UI can be built with a fake engine
// before FFmpeg, AVFoundation, Whisper, or Ollama are wired into the real app.

enum ForgeMediaPrivacyMode: String, Codable, DatabaseValueConvertible {
    case privacyOn = "privacy_on"
    case localAIOnly = "local_ai_only"
    case remoteAIOptIn = "remote_ai_opt_in"
}

enum JobPhase: String, Codable, DatabaseValueConvertible, CaseIterable {
    case idle
    case preparing
    case probing
    case planning
    case running
    case validating
    case completed
    case completedWithWarnings
    case failed
    case paused
    case canceled
    case recovered
}

enum ProgressConfidence: String, Codable, DatabaseValueConvertible {
    case unknown
    case estimated
    case measured
}

struct MediaPreset: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "presets"

    var id: String
    var name: String
    var engine: String
    var outputContainer: String
    var videoCodec: String?
    var audioCodec: String?
    var subtitleBehavior: String
    var privacyMode: ForgeMediaPrivacyMode
}

struct JobRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "jobs"

    var id: String
    var title: String
    var sourceURL: String
    var outputURL: String?
    var presetID: String
    var phase: JobPhase
    var progressFraction: Double
    var progressConfidence: ProgressConfidence
    var progressLabel: String
    var createdAt: Date
    var updatedAt: Date
    var lastCheckpoint: String?
    var privacyMode: ForgeMediaPrivacyMode
    var cancellationRequested: Bool
}

struct JobEvent: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "job_events"

    var id: String
    var jobID: String
    var phase: JobPhase
    var message: String
    var progressFraction: Double?
    var progressConfidence: ProgressConfidence?
    var createdAt: Date
}

protocol ProcessingEngine: Sendable {
    func probe(_ url: URL) async throws -> MediaProbeResult
    func run(_ job: JobRecord, preset: MediaPreset, progress: @Sendable @escaping (JobProgress) -> Void) async throws -> JobOutput
    func cancel(jobID: String) async
}

struct MediaProbeResult: Sendable {
    var duration: TimeInterval?
    var width: Int?
    var height: Int?
    var videoCodec: String?
    var audioCodec: String?
    var rotationDegrees: Int?
    var hdrMetadata: String?
    var estimatedOutputSize: Int64?
}

struct JobProgress: Sendable {
    var phase: JobPhase
    var label: String
    var fraction: Double
    var confidence: ProgressConfidence
    var lastCheckpoint: String?
}

struct JobOutput: Sendable {
    var url: URL
    var duration: TimeInterval?
    var width: Int?
    var height: Int?
    var videoCodec: String?
    var audioCodec: String?
    var checksum: String?
    var warnings: [String]
}

protocol TranscriptEngine: Sendable {
    func transcribe(
        mediaURL: URL,
        model: WhisperModelDescriptor,
        progress: @Sendable @escaping (TranscriptProgress) -> Void
    ) async throws -> TranscriptOutput
}

struct WhisperModelDescriptor: Sendable {
    var name: String
    var quantization: String
    var source: String
    var license: String
    var acceleration: WhisperAccelerationMode
}

enum WhisperAccelerationMode: String, Sendable {
    case cpu
    case metal
    case coreML
    case coreMLWithANEFallback
}

struct TranscriptProgress: Sendable {
    var segmentIndex: Int
    var segmentCount: Int
    var label: String
    var fraction: Double
}

struct TranscriptOutput: Sendable {
    var url: URL
    var format: TranscriptFormat
    var language: String?
    var wordTimings: Bool
}

enum TranscriptFormat: String, Sendable {
    case srt
    case vtt
    case json
}

protocol LocalAgentRouter: Sendable {
    func canUseLocalAgent(settings: PrivacySettings) -> Bool
    func route(_ request: AgentRequest, context: AgentContext) async throws -> AgentResponse
}

struct PrivacySettings: Sendable {
    var privacyMode: ForgeMediaPrivacyMode
    var allowLocalHistory: Bool
    var allowLocalCrashLogs: Bool
    var allowLocalOllama: Bool
    var allowRemoteAI: Bool
}

struct AgentRequest: Sendable {
    var intent: String
    var jobID: String?
    var allowedTools: [String]
    var budget: AgentBudget
}

struct AgentBudget: Sendable {
    var maxTokens: Int
    var maxSeconds: TimeInterval
    var allowGPUWhenMediaBusy: Bool
}

struct AgentContext: Sendable {
    var systemLoad: SystemLoadSnapshot
    var activeJobs: [JobRecord]
    var availableTools: [String]
}

struct SystemLoadSnapshot: Sendable {
    var cpuLoad: Double
    var memoryPressure: Double
    var gpuBusy: Bool
    var batterySaverMode: Bool
}

struct AgentResponse: Sendable {
    var plan: String
    var toolCalls: [AgentToolCall]
    var warnings: [String]
}

struct AgentToolCall: Sendable {
    var tool: String
    var argumentsJSON: Data
    var requiresUserConfirmation: Bool
}

struct DatabaseMigrations {
    static let all: [Migration] = [
        Migration(
            identifier: "2026061301-initial-schema",
            migrate: { db in
                try db.create(table: "presets") { t in
                    t.column("id", .text).primaryKey()
                    t.column("name", .text).notNull()
                    t.column("engine", .text).notNull()
                    t.column("outputContainer", .text).notNull()
                    t.column("videoCodec", .text)
                    t.column("audioCodec", .text)
                    t.column("subtitleBehavior", .text).notNull()
                    t.column("privacyMode", .text).notNull()
                }

                try db.create(table: "jobs") { t in
                    t.column("id", .text).primaryKey()
                    t.column("title", .text).notNull()
                    t.column("sourceURL", .text).notNull()
                    t.column("outputURL", .text)
                    t.column("presetID", .text).notNull()
                    t.column("phase", .text).notNull()
                    t.column("progressFraction", .double).notNull().defaults(to: 0)
                    t.column("progressConfidence", .text).notNull()
                    t.column("progressLabel", .text).notNull()
                    t.column("createdAt", .datetime).notNull()
                    t.column("updatedAt", .datetime).notNull()
                    t.column("lastCheckpoint", .text)
                    t.column("privacyMode", .text).notNull()
                    t.column("cancellationRequested", .boolean).notNull().defaults(to: false)
                }

                try db.create(table: "job_events") { t in
                    t.column("id", .text).primaryKey()
                    t.column("jobID", .text).notNull().indexed()
                    t.column("phase", .text).notNull()
                    t.column("message", .text).notNull()
                    t.column("progressFraction", .double)
                    t.column("progressConfidence", .text)
                    t.column("createdAt", .datetime).notNull()
                }
            },
            rollback: { db in
                try db.drop(table: "job_events")
                try db.drop(table: "jobs")
                try db.drop(table: "presets")
            }
        )
    ]
}

struct Migration {
    var identifier: String
    var migrate: (Database) throws -> Void
    var rollback: (Database) throws -> Void
}
