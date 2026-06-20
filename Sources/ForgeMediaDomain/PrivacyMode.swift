import Foundation

// ForgeMedia privacy posture — the default is always privacy-first.
//
// PrivacyOn:      no network, no telemetry, no cloud, local-only processing.
// localAIOnly:    local Ollama/llama.cpp allowed, no remote models.
// remoteAIOptIn:  user has explicitly enabled a remote AI endpoint.

public enum PrivacyMode: String, Codable, Sendable, CaseIterable {
    case privacyOn = "privacy_on"
    case localAIOnly = "local_ai_only"
    case remoteAIOptIn = "remote_ai_opt_in"
}