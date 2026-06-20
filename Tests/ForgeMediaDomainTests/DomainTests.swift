import XCTest
import Foundation
@testable import ForgeMediaDomain

final class PrivacySettingsTests: XCTestCase {
    func testDefaultIsPrivacyOn() {
        let settings = PrivacySettings()
        XCTAssertEqual(settings.privacyMode, .privacyOn)
        XCTAssertTrue(settings.isPrivacyOn)
        XCTAssertFalse(settings.canUseLocalAgent)
        XCTAssertFalse(settings.canUseRemoteAI)
    }

    func testLocalAIAllowed() {
        let settings = PrivacySettings(privacyMode: .localAIOnly, allowLocalOllama: true)
        XCTAssertTrue(settings.canUseLocalAgent)
        XCTAssertFalse(settings.canUseRemoteAI)
    }

    func testRemoteAIRequiresExplicitOptIn() {
        var settings = PrivacySettings(privacyMode: .remoteAIOptIn, allowRemoteAI: true)
        XCTAssertTrue(settings.canUseRemoteAI)
        settings.allowRemoteAI = false
        XCTAssertFalse(settings.canUseRemoteAI)
    }
}

final class JobPhaseTests: XCTestCase {
    func testAllPhasesHaveStringRepresentation() {
        for phase in JobPhase.allCases {
            XCTAssertFalse(phase.rawValue.isEmpty)
        }
    }
}

final class JobRecordTests: XCTestCase {
    func testWithUpdatesTimestamps() {
        let original = JobRecord(
            title: "test.mov",
            sourceURL: URL(fileURLWithPath: "/tmp/test.mov"),
            presetID: "convert_h264"
        )
        let updated = original.with(phase: .running, progressLabel: "Running…")
        XCTAssertEqual(updated.phase, .running)
        XCTAssertEqual(updated.title, original.title)
        XCTAssertEqual(updated.id, original.id)
        XCTAssertGreaterThanOrEqual(updated.updatedAt, original.createdAt)
    }
}

final class MediaProbeResultTests: XCTestCase {
    func testSummaryFormatting() {
        let result = MediaProbeResult(
            duration: 3661,
            width: 1920,
            height: 1080,
            videoCodec: "h264",
            audioCodec: "aac"
        )
        let summary = result.summary
        XCTAssertTrue(summary.contains("1:01:01"))
        XCTAssertTrue(summary.contains("1920×1080"))
        XCTAssertTrue(summary.contains("h264"))
        XCTAssertTrue(summary.contains("aac"))
    }
}