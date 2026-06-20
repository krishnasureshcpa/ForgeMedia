import Foundation
import GRDB
import ForgeMediaDomain

// MARK: - MediaPreset GRDB conformance

extension MediaPreset: FetchableRecord, PersistableRecord, TableRecord {
    public static var databaseTableName: String { "presets" }

    enum Columns: String, ColumnExpression {
        case id, name, engine, outputContainer, videoCodec, audioCodec, subtitleBehavior, privacyMode
    }

    public init(row: Row) throws {
        self.init(
            id: row[Columns.id],
            name: row[Columns.name],
            engine: row[Columns.engine],
            outputContainer: row[Columns.outputContainer],
            videoCodec: row[Columns.videoCodec],
            audioCodec: row[Columns.audioCodec],
            subtitleBehavior: row[Columns.subtitleBehavior],
            privacyMode: PrivacyMode(rawValue: row[Columns.privacyMode]) ?? .privacyOn
        )
    }

    public func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id
        container[Columns.name] = name
        container[Columns.engine] = engine
        container[Columns.outputContainer] = outputContainer
        container[Columns.videoCodec] = videoCodec
        container[Columns.audioCodec] = audioCodec
        container[Columns.subtitleBehavior] = subtitleBehavior
        container[Columns.privacyMode] = privacyMode.rawValue
    }
}

// MARK: - JobRecord GRDB conformance

extension JobRecord: FetchableRecord, PersistableRecord, TableRecord {
    public static var databaseTableName: String { "jobs" }

    enum Columns: String, ColumnExpression {
        case id, title, sourceURL, outputURL, presetID, phase, progressFraction,
             progressConfidence, progressLabel, createdAt, updatedAt, lastCheckpoint,
             privacyMode, cancellationRequested
    }

    public init(row: Row) throws {
        self.init(
            id: row[Columns.id],
            title: row[Columns.title],
            sourceURL: URL(fileURLWithPath: row[Columns.sourceURL]),
            outputURL: (row[Columns.outputURL] as String?).map { URL(fileURLWithPath: $0) },
            presetID: row[Columns.presetID],
            phase: JobPhase(rawValue: row[Columns.phase]) ?? .idle,
            progressFraction: row[Columns.progressFraction],
            progressConfidence: ProgressConfidence(rawValue: row[Columns.progressConfidence]) ?? .unknown,
            progressLabel: row[Columns.progressLabel],
            createdAt: row[Columns.createdAt],
            updatedAt: row[Columns.updatedAt],
            lastCheckpoint: row[Columns.lastCheckpoint],
            privacyMode: PrivacyMode(rawValue: row[Columns.privacyMode]) ?? .privacyOn,
            cancellationRequested: row[Columns.cancellationRequested]
        )
    }

    public func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id
        container[Columns.title] = title
        container[Columns.sourceURL] = sourceURL.path
        container[Columns.outputURL] = outputURL?.path
        container[Columns.presetID] = presetID
        container[Columns.phase] = phase.rawValue
        container[Columns.progressFraction] = progressFraction
        container[Columns.progressConfidence] = progressConfidence.rawValue
        container[Columns.progressLabel] = progressLabel
        container[Columns.createdAt] = createdAt
        container[Columns.updatedAt] = updatedAt
        container[Columns.lastCheckpoint] = lastCheckpoint
        container[Columns.privacyMode] = privacyMode.rawValue
        container[Columns.cancellationRequested] = cancellationRequested
    }
}

// MARK: - JobEvent GRDB conformance

extension JobEvent: FetchableRecord, PersistableRecord, TableRecord {
    public static var databaseTableName: String { "jobEvents" }

    enum Columns: String, ColumnExpression {
        case id, jobID, phase, message, progressFraction, progressConfidence, createdAt
    }

    public init(row: Row) throws {
        self.init(
            id: row[Columns.id],
            jobID: row[Columns.jobID],
            phase: JobPhase(rawValue: row[Columns.phase]) ?? .idle,
            message: row[Columns.message],
            progressFraction: row[Columns.progressFraction],
            progressConfidence: (row[Columns.progressConfidence] as String?).map { ProgressConfidence(rawValue: $0) ?? .unknown },
            createdAt: row[Columns.createdAt]
        )
    }

    public func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id
        container[Columns.jobID] = jobID
        container[Columns.phase] = phase.rawValue
        container[Columns.message] = message
        container[Columns.progressFraction] = progressFraction
        container[Columns.progressConfidence] = progressConfidence?.rawValue
        container[Columns.createdAt] = createdAt
    }
}