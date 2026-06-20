import XCTest
import Foundation
@testable import ForgeMediaMedia
@testable import ForgeMediaDomain

final class FakeProcessingEngineTests: XCTestCase {
    func testProbeReturnsValidData() async throws {
        let engine = FakeProcessingEngine()
        let result = try await engine.probe(URL(fileURLWithPath: "/tmp/test.mp4"))
        XCTAssertNotNil(result.duration)
        XCTAssertNotNil(result.width)
        XCTAssertNotNil(result.height)
        XCTAssertFalse(result.videoCodec!.isEmpty)
    }

    func testRunEmitsProgressAndReturnsOutput() async throws {
        let engine = FakeProcessingEngine()
        var progressValues: [Double] = []

        let job = JobRecord(
            title: "test_fake.mp4",
            sourceURL: URL(fileURLWithPath: "/tmp/test_fake.mp4"),
            presetID: "convert_h264",
            phase: .running
        )

        let output = try await engine.run(job, preset: MediaPreset.builtIn[1], progress: { p in
            progressValues.append(p.fraction)
        })

        XCTAssertGreaterThanOrEqual(progressValues.count, 3, "Should emit at least 3 progress updates")
        XCTAssertEqual(progressValues.last!, 1.0)
        XCTAssertFalse(output.url.path.isEmpty)
        XCTAssertNotNil(output.videoCodec)
    }

    func testCancelStopsRun() async throws {
        let engine = FakeProcessingEngine()
        let job = JobRecord(
            title: "cancelable.mp4",
            sourceURL: URL(fileURLWithPath: "/tmp/cancelable.mp4"),
            presetID: "convert_h264",
            phase: .running
        )

        Task {
            try? await Task.sleep(for: .milliseconds(200))
            await engine.cancel(jobID: job.id)
        }

        do {
            _ = try await engine.run(job, preset: MediaPreset.builtIn[1], progress: { _ in })
            XCTFail("Should have thrown CancellationError")
        } catch is CancellationError {
            // Expected
        }
    }
}