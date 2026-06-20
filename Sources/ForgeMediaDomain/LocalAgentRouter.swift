import Foundation

// MARK: - Local agent router protocol

/// Routes natural-language intents to local AI tools.
/// Only available when privacy settings allow local agent use.
public protocol LocalAgentRouter: Sendable {
    func canUseLocalAgent(settings: PrivacySettings) -> Bool
    func route(_ request: AgentRequest, context: AgentContext) async throws -> AgentResponse
}

// MARK: - Agent request

public struct AgentRequest: Sendable {
    public var intent: String
    public var jobID: String?
    public var allowedTools: [String]
    public var budget: AgentBudget

    public init(intent: String, jobID: String? = nil, allowedTools: [String] = [], budget: AgentBudget = .default) {
        self.intent = intent
        self.jobID = jobID
        self.allowedTools = allowedTools
        self.budget = budget
    }
}

public struct AgentBudget: Sendable, Equatable {
    public var maxTokens: Int
    public var maxSeconds: TimeInterval
    public var allowGPUWhenMediaBusy: Bool

    public static let `default` = AgentBudget(maxTokens: 4096, maxSeconds: 60, allowGPUWhenMediaBusy: false)

    public init(maxTokens: Int, maxSeconds: TimeInterval, allowGPUWhenMediaBusy: Bool) {
        self.maxTokens = maxTokens
        self.maxSeconds = maxSeconds
        self.allowGPUWhenMediaBusy = allowGPUWhenMediaBusy
    }
}

// MARK: - Agent context (system state snapshot)

public struct AgentContext: Sendable {
    public var systemLoad: SystemLoadSnapshot
    public var activeJobs: [JobRecord]
    public var availableTools: [String]

    public init(systemLoad: SystemLoadSnapshot, activeJobs: [JobRecord] = [], availableTools: [String] = []) {
        self.systemLoad = systemLoad
        self.activeJobs = activeJobs
        self.availableTools = availableTools
    }
}

public struct SystemLoadSnapshot: Sendable, Equatable {
    public var cpuLoad: Double       // 0.0 … 1.0
    public var memoryPressure: Double // 0.0 … 1.0
    public var gpuBusy: Bool
    public var batterySaverMode: Bool

    public init(cpuLoad: Double = 0, memoryPressure: Double = 0, gpuBusy: Bool = false, batterySaverMode: Bool = false) {
        self.cpuLoad = cpuLoad
        self.memoryPressure = memoryPressure
        self.gpuBusy = gpuBusy
        self.batterySaverMode = batterySaverMode
    }
}

// MARK: - Agent response

public struct AgentResponse: Sendable {
    public var plan: String
    public var toolCalls: [AgentToolCall]
    public var warnings: [String]

    public init(plan: String, toolCalls: [AgentToolCall] = [], warnings: [String] = []) {
        self.plan = plan
        self.toolCalls = toolCalls
        self.warnings = warnings
    }
}

public struct AgentToolCall: Sendable {
    public var tool: String
    public var argumentsJSON: Data
    public var requiresUserConfirmation: Bool

    public init(tool: String, argumentsJSON: Data, requiresUserConfirmation: Bool = false) {
        self.tool = tool
        self.argumentsJSON = argumentsJSON
        self.requiresUserConfirmation = requiresUserConfirmation
    }
}