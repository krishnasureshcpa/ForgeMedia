import Foundation
import ForgeMediaDomain

/// Local Ollama client stub.
///
/// In the real implementation, this talks to the Ollama API at `http://localhost:11434/v1/`.
/// Right now it returns canned responses — enough to build the UI and agent routing logic.
public actor OllamaClient {
    private let baseURL: URL
    private let session: URLSession

    public init(baseURL: URL = URL(string: "http://localhost:11434")!) {
        self.baseURL = baseURL
        self.session = URLSession(configuration: .ephemeral)
    }

    /// Check connectivity. Returns false if Ollama is not running.
    public func healthCheck() async -> Bool {
        // Stub: always returns true during UI development
        return true
    }

    /// List available local models.
    public func listModels() async throws -> [String] {
        // Stub: returns an example list
        return ["llama3.2:3b", "qwen2.5:7b", "deepseek-r1:8b"]
    }

    /// Generate a completion from a local model.
    /// Stub returns canned content; the real implementation POSTs to `/v1/chat/completions`.
    public func generate(prompt: String, model: String = "qwen2.5:7b", maxTokens: Int = 2048) async throws -> String {
        // Stub response for UI development
        return "I would suggest processing this media file with the following plan: 1) probe the file, 2) split into segments, 3) transcribe with whisper, 4) validate output quality."
    }
}

// MARK: - LocalAgentRouter implementation

/// Stub local agent router — gates local AI access behind privacy settings.
public final class StubLocalAgentRouter: LocalAgentRouter, @unchecked Sendable {
    private let ollama: OllamaClient

    public init(ollama: OllamaClient = OllamaClient()) {
        self.ollama = ollama
    }

    public func canUseLocalAgent(settings: PrivacySettings) -> Bool {
        settings.canUseLocalAgent
    }

    public func route(_ request: AgentRequest, context: AgentContext) async throws -> AgentResponse {
        guard await ollama.healthCheck() else {
            throw AgentError.ollamaUnavailable
        }
        // Stub: return canned routing
        return AgentResponse(plan: "Analyze media, split into 14 segments, transcribe each, merge output.", warnings: [])
    }
}

public enum AgentError: Error, LocalizedError {
    case ollamaUnavailable
    case privacyBlocked
    case budgetExceeded

    public var errorDescription: String? {
        switch self {
        case .ollamaUnavailable: return "Ollama is not running on this Mac."
        case .privacyBlocked: return "Local AI is disabled in privacy settings."
        case .budgetExceeded: return "Agent budget exceeded. Try a smaller request."
        }
    }
}