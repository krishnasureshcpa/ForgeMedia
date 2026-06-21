import Foundation
import GRDB
import ForgeMediaDomain

/// Manages the GRDB DatabaseQueue and migrations.
public final class DatabaseService: @unchecked Sendable {
    private let writer: DatabaseQueue

    public init(path: String) throws {
        writer = try DatabaseQueue(path: path)
        try runMigrations()
    }

    /// In-memory database for testing.
    public static func inMemory() throws -> DatabaseService {
        let svc = try DatabaseService(path: ":memory:")
        return svc
    }

    // MARK: - Database access

    /// Read from the database (synchronous, wrapped for convenience).
    public func read<T>(_ block: @escaping (GRDB.Database) throws -> T) throws -> T {
        try writer.read(block)
    }

    /// Write to the database (synchronous, wrapped for convenience).
    @discardableResult
    public func write<T>(_ block: @escaping (GRDB.Database) throws -> T) throws -> T {
        try writer.write(block)
    }

    public var reader: any GRDB.DatabaseReader { writer }

    // MARK: - Migrations

    private func runMigrations() throws {
        var migrator = DatabaseMigrator()

        // v1 — Initial schema
        migrator.registerMigration("v1_initial_schema") { db in
            try db.create(table: "presets") { t in
                t.column("id", .text).primaryKey()
                t.column("name", .text).notNull()
                t.column("engine", .text).notNull()
                t.column("outputContainer", .text).notNull()
                t.column("videoCodec", .text)
                t.column("audioCodec", .text)
                t.column("subtitleBehavior", .text).notNull().defaults(to: "none")
                t.column("privacyMode", .text).notNull().defaults(to: "privacy_on")
            }

            try db.create(table: "jobs") { t in
                t.column("id", .text).primaryKey()
                t.column("title", .text).notNull()
                t.column("sourceURL", .text).notNull()
                t.column("outputURL", .text)
                t.column("presetID", .text).notNull()
                t.column("phase", .text).notNull().defaults(to: "idle")
                t.column("progressFraction", .double).notNull().defaults(to: 0)
                t.column("progressConfidence", .text).notNull().defaults(to: "unknown")
                t.column("progressLabel", .text).notNull().defaults(to: "")
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
                t.column("lastCheckpoint", .text)
                t.column("privacyMode", .text).notNull().defaults(to: "privacy_on")
                t.column("cancellationRequested", .boolean).notNull().defaults(to: false)
            }

            try db.create(table: "jobEvents") { t in
                t.column("id", .text).primaryKey()
                t.column("jobID", .text).notNull().indexed()
                t.column("phase", .text).notNull()
                t.column("message", .text).notNull()
                t.column("progressFraction", .double)
                t.column("progressConfidence", .text)
                t.column("createdAt", .datetime).notNull()
            }

            try db.create(table: "privacySettings") { t in
                t.column("key", .text).primaryKey()
                t.column("value", .text).notNull()
            }

            try db.create(table: "agentRuns") { t in
                t.column("id", .text).primaryKey()
                t.column("jobID", .text)
                t.column("role", .text).notNull()
                t.column("model", .text)
                t.column("promptHash", .text)
                t.column("outputSummary", .text)
                t.column("tokenEstimate", .integer)
                t.column("createdAt", .datetime).notNull()
            }

            // Seed built-in presets
            for preset in MediaPreset.builtIn {
                try db.execute(
                    sql: """
                        INSERT OR IGNORE INTO presets (id, name, engine, outputContainer, videoCodec, audioCodec, subtitleBehavior, privacyMode)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                        """,
                    arguments: [preset.id, preset.name, preset.engine, preset.outputContainer,
                                preset.videoCodec, preset.audioCodec, preset.subtitleBehavior,
                                preset.privacyMode.rawValue]
                )
            }
        }

        // v2 — Language detection fields on jobs table
        migrator.registerMigration("v2_language_fields") { db in
            try db.alter(table: "jobs") { t in
                t.add(column: "detectedSourceLanguage", .text)
                t.add(column: "confirmedSourceLanguage", .text)
                t.add(column: "targetLanguage", .text).defaults(to: "en")
            }
        }

        // v3 — Intake root folder for output naming (folder suffix mirroring)
        migrator.registerMigration("v3_intake_root_folder") { db in
            try db.alter(table: "jobs") { t in
                t.add(column: "intakeRootFolderURL", .text)
            }
        }

        try migrator.migrate(writer)
    }
}