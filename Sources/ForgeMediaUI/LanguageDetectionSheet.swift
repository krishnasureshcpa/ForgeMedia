import SwiftUI
import ForgeMediaDomain

/// Sheet shown after file intake. Displays per-file detected source languages
/// and lets the user correct them before processing begins.
public struct LanguageDetectionSheet: View {
    /// Per-file detection results keyed by URL.
    public let detectionResults: [URL: LanguageDetectionResult]

    /// Called when user taps "Confirm & Process".
    /// Passes per-URL confirmed language codes and a global target language code.
    public let onConfirm: (_ overrides: [URL: String], _ targetLanguage: String) -> Void

    /// Called when user cancels; queued files are discarded.
    public let onCancel: () -> Void

    // Per-file confirmed source language (initially set from detection result)
    @State private var confirmedSources: [URL: LanguageOption] = [:]
    @State private var targetLanguage: LanguageOption = LanguageOption.find(id: "en")

    private var sortedURLs: [URL] {
        detectionResults.keys.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    public init(
        detectionResults: [URL: LanguageDetectionResult],
        onConfirm: @escaping (_ overrides: [URL: String], _ targetLanguage: String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.detectionResults = detectionResults
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "waveform.and.magnifyingglass")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(ForgeMediaTokens.Colors.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Language Detection")
                        .font(.system(.headline, design: .default).weight(.semibold))
                        .foregroundColor(ForgeMediaTokens.Colors.fg)
                    Text("Review detected languages before processing begins")
                        .font(.system(.subheadline, design: .default))
                        .foregroundColor(ForgeMediaTokens.Colors.muted)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 14)

            Divider()

            // Per-file rows
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(sortedURLs, id: \.self) { url in
                        if let result = detectionResults[url] {
                            FileLanguageRow(
                                url: url,
                                result: result,
                                confirmed: binding(for: url, fallback: result.language)
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .frame(maxHeight: 320)

            Divider()

            // Target language + action buttons
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: "globe")
                        .font(.system(size: 14))
                        .foregroundColor(ForgeMediaTokens.Colors.accent)

                    Text("Output Language")
                        .font(.system(.callout, design: .default).weight(.medium))
                        .foregroundColor(ForgeMediaTokens.Colors.fg)

                    Spacer()

                    LanguagePickerView(selection: $targetLanguage, includeAuto: false)
                }
                .padding(.horizontal, 20)

                HStack(spacing: 10) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.escape, modifiers: [])

                    Spacer()

                    Button("Confirm & Process") {
                        var overrides: [URL: String] = [:]
                        for url in sortedURLs {
                            let chosen = confirmedSources[url] ?? detectionResults[url]?.language ?? .auto
                            overrides[url] = chosen.id
                        }
                        onConfirm(overrides, targetLanguage.id)
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return, modifiers: [.command])
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 16)
        }
        .background(ForgeMediaTokens.Glass.floating)
        .frame(width: 560)
        .onAppear { prepopulate() }
    }

    // MARK: - Helpers

    private func prepopulate() {
        for (url, result) in detectionResults {
            confirmedSources[url] = result.language
        }
    }

    private func binding(for url: URL, fallback: LanguageOption) -> Binding<LanguageOption> {
        Binding(
            get: { confirmedSources[url] ?? fallback },
            set: { confirmedSources[url] = $0 }
        )
    }
}

// MARK: - FileLanguageRow

private struct FileLanguageRow: View {
    let url: URL
    let result: LanguageDetectionResult
    @Binding var confirmed: LanguageOption

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            // File icon + name
            Image(systemName: "film")
                .font(.system(size: 14))
                .foregroundColor(ForgeMediaTokens.Colors.muted)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(url.lastPathComponent)
                    .font(.system(.callout, design: .default))
                    .foregroundColor(ForgeMediaTokens.Colors.fg)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    confidenceChip
                    Text("via \(result.source.rawValue)")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(ForgeMediaTokens.Colors.muted)
                }
            }

            Spacer()

            LanguagePickerView(selection: $confirmed, includeAuto: true)

            // Warning dot if needs confirmation
            if result.needsUserConfirmation {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(ForgeMediaTokens.Colors.warning)
                    .help("Low confidence — please verify")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isHovered ? ForgeMediaTokens.Glass.elevated : ForgeMediaTokens.Glass.surface)
        .clipShape(RoundedRectangle(cornerRadius: ForgeMediaTokens.Radii.compact, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ForgeMediaTokens.Radii.compact, style: .continuous)
                .stroke(
                    result.needsUserConfirmation
                        ? ForgeMediaTokens.Colors.warning.opacity(0.4)
                        : ForgeMediaTokens.Colors.border,
                    lineWidth: 0.5
                )
        )
        .animation(ForgeMediaTokens.Motion.snappy, value: isHovered)
        .onHover { isHovered = $0 }
    }

    private var confidenceChip: some View {
        let pct = Int(result.confidence * 100)
        let color: Color = result.confidence >= 0.85
            ? ForgeMediaTokens.Colors.success
            : result.confidence >= 0.6
                ? ForgeMediaTokens.Colors.warning
                : ForgeMediaTokens.Colors.danger

        return Text("\(pct)%")
            .font(.system(.caption2, design: .monospaced).weight(.medium))
            .foregroundColor(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(color.opacity(0.1))
            .clipShape(Capsule(style: .continuous))
    }
}
