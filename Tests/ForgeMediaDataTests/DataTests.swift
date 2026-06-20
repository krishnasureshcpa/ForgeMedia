import XCTest
import Foundation
@testable import ForgeMediaData
@testable import ForgeMediaDomain

final class DatabaseServiceTests: XCTestCase {
    func testInMemoryDatabaseCreatesTables() throws {
        let db = try DatabaseService.inMemory()

        let presets = try db.read { db in
            try MediaPreset.fetchAll(db)
        }
        XCTAssertGreaterThanOrEqual(presets.count, 5, "Built-in presets should be seeded")

        let job = JobRecord(
            title: "test.mp4",
            sourceURL: URL(fileURLWithPath: "/tmp/test.mp4"),
            presetID: "convert_h264"
        )
        try db.write { db in
            try job.insert(db)
        }

        let fetched = try db.read { db in
            try JobRecord.fetchOne(db, key: job.id)
        }
        XCTAssertEqual(fetched?.title, "test.mp4")
    }
}

final class JobRepositoryTests: XCTestCase {
    func testUpsertAndFetch() throws {
        let db = try DatabaseService.inMemory()
        let repo = JobRepository(db: db)

        let job = JobRecord(title: "interview.mp4", sourceURL: URL(fileURLWithPath: "/tmp/interview.mp4"), presetID: "transcribe")
        try repo.upsert(job)

        let all = try repo.all()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all[0].title, "interview.mp4")
    }

    func testCancelSetsFlag() throws {
        let db = try DatabaseService.inMemory()
        let repo = JobRepository(db: db)

        let job = JobRecord(title: "large.mov", sourceURL: URL(fileURLWithPath: "/tmp/large.mov"), presetID: "convert_h264")
        try repo.upsert(job)

        try repo.requestCancellation(jobID: job.id)

        let updated = try repo.fetch(id: job.id)
        XCTAssertEqual(updated?.cancellationRequested, true)
    }

    func testEventsAreAssociatedWithJob() throws {
        let db = try DatabaseService.inMemory()
        let repo = JobRepository(db: db)

        let job = JobRecord(title: "eventful.mp4", sourceURL: URL(fileURLWithPath: "/tmp/eventful.mp4"), presetID: "convert_h264")
        try repo.upsert(job)

        try repo.insertEvent(JobEvent(jobID: job.id, phase: .running, message: "Started"))
        try repo.insertEvent(JobEvent(jobID: job.id, phase: .completed, message: "Done"))

        let events = try repo.events(for: job.id)
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events[0].message, "Started")
        XCTAssertEqual(events[1].message, "Done")
    }
}