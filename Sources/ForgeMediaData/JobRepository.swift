import Foundation
import GRDB
import ForgeMediaDomain

/// Repository for CRUD operations on JobRecord.
///
/// Uses GRDB ValueObservation to stream real-time job list updates to SwiftUI.
public final class JobRepository: @unchecked Sendable {
    private let db: DatabaseService

    public init(db: DatabaseService) {
        self.db = db
    }

    // MARK: - Read

    /// Returns all jobs ordered newest-first.
    public func all() throws -> [JobRecord] {
        try db.read { db in
            try JobRecord
                .order(Column("createdAt").desc)
                .fetchAll(db)
        }
    }

    /// Returns a single job by ID.
    public func fetch(id: String) throws -> JobRecord? {
        try db.read { db in
            try JobRecord.fetchOne(db, key: id)
        }
    }

    /// Returns the count of currently active jobs.
    public func activeCount() throws -> Int {
        try db.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM jobs WHERE phase IN ('running','preparing','probing','planning','validating','paused')") ?? 0
        }
    }

    /// ValueObservation that streams all jobs for SwiftUI.
    public func observeAll() -> ValueObservation<ValueReducers.Fetch<[JobRecord]>> {
        ValueObservation.trackingConstantRegion { db in
            try JobRecord
                .order(Column("createdAt").desc)
                .fetchAll(db)
        }
    }

    /// Observation for a single job.
    public func observe(id: String) -> ValueObservation<ValueReducers.Fetch<JobRecord?>> {
        ValueObservation.trackingConstantRegion { db in
            try JobRecord.fetchOne(db, key: id)
        }
    }

    // MARK: - Write

    /// Insert or replace a job.
    public func upsert(_ job: JobRecord) throws {
        try db.write { db in
            try job.upsert(db)
        }
    }

    /// Update a job's phase, progress, and related fields.
    public func updateProgress(jobID: String, phase: JobPhase, fraction: Double, confidence: ProgressConfidence, label: String, checkpoint: String?) throws {
        try db.write { db in
            try db.execute(
                sql: """
                    UPDATE jobs
                    SET phase = ?, progressFraction = ?, progressConfidence = ?, progressLabel = ?, lastCheckpoint = ?, updatedAt = ?
                    WHERE id = ?
                    """,
                arguments: [phase.rawValue, fraction, confidence.rawValue, label, checkpoint, Date(), jobID]
            )
        }
    }

    /// Request cancellation for a job. The worker observes this flag and responds.
    public func requestCancellation(jobID: String) throws {
        try db.write { db in
            try db.execute(
                sql: "UPDATE jobs SET cancellationRequested = 1, updatedAt = ? WHERE id = ?",
                arguments: [Date(), jobID]
            )
        }
    }

    /// Delete a job and its events.
    public func delete(jobID: String) throws {
        try db.write { db in
            try db.execute(sql: "DELETE FROM jobEvents WHERE jobID = ?", arguments: [jobID])
            try JobRecord.deleteOne(db, key: jobID)
        }
    }
}

// MARK: - JobEvent helpers

extension JobRepository {
    public func insertEvent(_ event: JobEvent) throws {
        try db.write { db in
            try event.insert(db)
        }
    }

    public func events(for jobID: String) throws -> [JobEvent] {
        try db.read { db in
            try JobEvent
                .filter(Column("jobID") == jobID)
                .order(Column("createdAt").asc)
                .fetchAll(db)
        }
    }

    /// Most recent N events across all jobs, newest first.
    public func recentEvents(limit: Int = 100) throws -> [JobEvent] {
        try db.read { db in
            try JobEvent
                .order(Column("createdAt").desc)
                .limit(limit)
                .fetchAll(db)
        }
    }

    /// ValueObservation streaming the most recent events for the activity panel.
    public func observeRecentEvents(limit: Int = 100) -> ValueObservation<ValueReducers.Fetch<[JobEvent]>> {
        ValueObservation.trackingConstantRegion { db in
            try JobEvent
                .order(Column("createdAt").desc)
                .limit(limit)
                .fetchAll(db)
        }
    }
}