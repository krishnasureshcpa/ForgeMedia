import Foundation

/// An auditable event attached to a job.
public struct JobEvent: Codable, Sendable, Identifiable, Equatable {
    public var id: String
    public var jobID: String
    public var phase: JobPhase
    public var message: String
    public var progressFraction: Double?
    public var progressConfidence: ProgressConfidence?
    public var createdAt: Date

    public init(
        id: String = UUID().uuidString,
        jobID: String,
        phase: JobPhase,
        message: String,
        progressFraction: Double? = nil,
        progressConfidence: ProgressConfidence? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.jobID = jobID
        self.phase = phase
        self.message = message
        self.progressFraction = progressFraction
        self.progressConfidence = progressConfidence
        self.createdAt = createdAt
    }
}