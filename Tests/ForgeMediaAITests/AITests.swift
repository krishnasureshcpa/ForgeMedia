import XCTest
import Foundation
@testable import ForgeMediaAI
@testable import ForgeMediaDomain

final class OllamaClientTests: XCTestCase {
    func testHealthCheckReturnsTrue() async {
        let client = OllamaClient()
        let healthy = await client.healthCheck()
        XCTAssertTrue(healthy)
    }

    func testListModelsReturnsExpected() async throws {
        let client = OllamaClient()
        let models = try await client.listModels()
        XCTAssertFalse(models.isEmpty)
        XCTAssertTrue(models.contains("llama3.2:3b"))
    }

    func testGenerateReturnsNonEmpty() async throws {
        let client = OllamaClient()
        let response = try await client.generate(prompt: "Plan a media processing pipeline")
        XCTAssertFalse(response.isEmpty)
    }
}

final class StubLocalAgentRouterTests: XCTestCase {
    func testBlocksWhenPrivacyOn() {
        let router = StubLocalAgentRouter()
        let settings = PrivacySettings(privacyMode: .privacyOn)
        XCTAssertFalse(router.canUseLocalAgent(settings: settings))
    }

    func testAllowsWhenLocalAIAndOllamaEnabled() {
        let router = StubLocalAgentRouter()
        let settings = PrivacySettings(privacyMode: .localAIOnly, allowLocalOllama: true)
        XCTAssertTrue(router.canUseLocalAgent(settings: settings))
    }
}