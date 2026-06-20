import Foundation

// MARK: - Privacy settings (persisted to local SQLite)

public struct PrivacySettings: Sendable, Equatable {
    public var privacyMode: PrivacyMode
    public var allowLocalHistory: Bool
    public var allowLocalCrashLogs: Bool
    public var allowLocalTranscriptCache: Bool
    public var allowLocalAgentHistory: Bool
    public var allowLocalOllama: Bool
    public var allowRemoteAI: Bool

    public init(
        privacyMode: PrivacyMode = .privacyOn,
        allowLocalHistory: Bool = false,
        allowLocalCrashLogs: Bool = false,
        allowLocalTranscriptCache: Bool = false,
        allowLocalAgentHistory: Bool = false,
        allowLocalOllama: Bool = false,
        allowRemoteAI: Bool = false
    ) {
        self.privacyMode = privacyMode
        self.allowLocalHistory = allowLocalHistory
        self.allowLocalCrashLogs = allowLocalCrashLogs
        self.allowLocalTranscriptCache = allowLocalTranscriptCache
        self.allowLocalAgentHistory = allowLocalAgentHistory
        self.allowLocalOllama = allowLocalOllama
        self.allowRemoteAI = allowRemoteAI
    }

    /// Privacy On means no network activity at all.
    public var isPrivacyOn: Bool { privacyMode == .privacyOn }

    /// Local-only AI via Ollama is allowed.
    public var canUseLocalAgent: Bool {
        (privacyMode == .localAIOnly || privacyMode == .remoteAIOptIn) && allowLocalOllama
    }

    /// Remote AI requires explicit opt-in.
    public var canUseRemoteAI: Bool {
        privacyMode == .remoteAIOptIn && allowRemoteAI
    }
}