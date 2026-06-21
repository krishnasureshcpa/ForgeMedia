import Foundation

/// A processing job stored in the local SQLite queue.
public struct JobRecord: Codable, Sendable, Identifiable, Equatable {
    public var id: String
    public var title: String
    public var sourceURL: URL
    public var outputURL: URL?
    public var presetID: String
    public var phase: JobPhase
    public var progressFraction: Double         // 0.0 … 1.0
    public var progressConfidence: ProgressConfidence
    public var progressLabel: String            // "Transcribing segment 8 of 14…"
    public var createdAt: Date
    public var updatedAt: Date
    public var lastCheckpoint: String?          // segment or byte-offset marker
    public var privacyMode: PrivacyMode
    public var cancellationRequested: Bool
    /// BCP-47 code detected by LanguageDetectionService ("es", "fr", "und", …)
    public var detectedSourceLanguage: String?
    /// BCP-47 code confirmed by the user (overrides detected; nil = use detected)
    public var confirmedSourceLanguage: String?
    /// BCP-47 target output language (default "en", used for transcription/dubbing)
    public var targetLanguage: String

    /// The effective source language: confirmed if set, else detected, else "auto"
    public var effectiveSourceLanguage: String {
        confirmedSourceLanguage ?? detectedSourceLanguage ?? "auto"
    }

    public init(
        id: String = UUID().uuidString,
        title: String,
        sourceURL: URL,
        outputURL: URL? = nil,
        presetID: String,
        phase: JobPhase = .idle,
        progressFraction: Double = 0,
        progressConfidence: ProgressConfidence = .unknown,
        progressLabel: String = "",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastCheckpoint: String? = nil,
        privacyMode: PrivacyMode = .privacyOn,
        cancellationRequested: Bool = false,
        detectedSourceLanguage: String? = nil,
        confirmedSourceLanguage: String? = nil,
        targetLanguage: String = "en"
    ) {
        self.id = id
        self.title = title
        self.sourceURL = sourceURL
        self.outputURL = outputURL
        self.presetID = presetID
        self.phase = phase
        self.progressFraction = progressFraction
        self.progressConfidence = progressConfidence
        self.progressLabel = progressLabel
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastCheckpoint = lastCheckpoint
        self.privacyMode = privacyMode
        self.cancellationRequested = cancellationRequested
        self.detectedSourceLanguage = detectedSourceLanguage
        self.confirmedSourceLanguage = confirmedSourceLanguage
        self.targetLanguage = targetLanguage
    }

    /// Returns a new record with the given fields updated; id/createdAt are preserved.
    public func with(
        phase: JobPhase? = nil,
        progressFraction: Double? = nil,
        progressConfidence: ProgressConfidence? = nil,
        progressLabel: String? = nil,
        outputURL: URL? = nil,
        lastCheckpoint: String? = nil,
        cancellationRequested: Bool? = nil,
        detectedSourceLanguage: String?? = nil,
        confirmedSourceLanguage: String?? = nil,
        targetLanguage: String? = nil
    ) -> JobRecord {
        var copy = self
        if let phase { copy.phase = phase }
        if let progressFraction { copy.progressFraction = progressFraction }
        if let progressConfidence { copy.progressConfidence = progressConfidence }
        if let progressLabel { copy.progressLabel = progressLabel }
        if let outputURL { copy.outputURL = outputURL }
        if let lastCheckpoint { copy.lastCheckpoint = lastCheckpoint }
        if let cancellationRequested { copy.cancellationRequested = cancellationRequested }
        if let detectedSourceLanguage { copy.detectedSourceLanguage = detectedSourceLanguage }
        if let confirmedSourceLanguage { copy.confirmedSourceLanguage = confirmedSourceLanguage }
        if let targetLanguage { copy.targetLanguage = targetLanguage }
        copy.updatedAt = Date()
        return copy
    }
}