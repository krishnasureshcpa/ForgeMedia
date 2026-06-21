import SwiftUI
import ForgeMediaDomain

/// Sheet shown after file intake. Displays per-file detected source languages
/// and lets the user correct them before processing begins.
/// Styled with Nostalgia design tokens: cream window · 1px taupe borders.
public struct LanguageDetectionSheet: View {
    public let detectionResults: [URL: LanguageDetectionResult]
    public let onConfirm: (_ overrides: [URL: String], _ targetLanguage: String) -> Void
    public let onCancel: () -> Void

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
            sheetTitleBar
            Divider().overlay(ForgeMediaTokens.Colors.borderDefault)
            fileList
            Divider().overlay(ForgeMediaTokens.Colors.borderDefault)
            footerRow
        }
        .background(ForgeMediaTokens.Colors.canvas)
        .frame(width: 560)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(ForgeMediaTokens.Colors.borderDefault, lineWidth: 1)
        )
        .shadow(
            color: ForgeMediaTokens.Shadow.windowLo.color,
            radius: ForgeMediaTokens.Shadow.windowLo.radius,
            x: 0, y: ForgeMediaTokens.Shadow.windowLo.y
        )
        .shadow(
            color: ForgeMediaTokens.Shadow.windowHi.color,
            radius: ForgeMediaTokens.Shadow.windowHi.radius,
            x: 0, y: ForgeMediaTokens.Shadow.windowHi.y
        )
        .onAppear { prepopulate() }
    }

    // MARK: - Title Bar

    private var sheetTitleBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "waveform.and.magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ForgeMediaTokens.Colors.brand)

            VStack(alignment: .leading, spacing: 1) {
                Text("Language Detection")
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .foregroundColor(ForgeMediaTokens.Colors.heading)
                Text("Review detected languages before processing begins")
                    .font(.system(size: 11))
                    .foregroundColor(ForgeMediaTokens.Colors.bodySubtle)
            }

            Spacer()

            Text("\(detectionResults.count) file\(detectionResults.count == 1 ? "" : "s")")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(ForgeMediaTokens.Colors.bodySubtle)
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(ForgeMediaTokens.Colors.menuBar)
    }

    // MARK: - File List

    private var fileList: some View {
        ScrollView {
            VStack(spacing: 4) {
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
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .frame(maxHeight: 280)
        .background(ForgeMediaTokens.Colors.canvas)
    }

    // MARK: - Footer

    private var footerRow: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "globe")
                    .font(.system(size: 13))
                    .foregroundColor(ForgeMediaTokens.Colors.brand)

                Text("Output language")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ForgeMediaTokens.Colors.body)

                Spacer()

                LanguagePickerView(selection: $targetLanguage, includeAuto: false)
            }

            HStack {
                Button("Cancel") { onCancel() }
                    .buttonStyle(ForgeButtonStyle(.outline))
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
                .buttonStyle(ForgeButtonStyle(.primary))
                .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(ForgeMediaTokens.Colors.secondarySurface)
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
            Image(systemName: "film")
                .font(.system(size: 13))
                .foregroundColor(ForgeMediaTokens.Colors.bodySubtle)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(url.lastPathComponent)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(ForgeMediaTokens.Colors.heading)
                    .lineLimit(1)

                HStack(spacing: 5) {
                    confidenceChip
                    Text("via \(result.source.rawValue)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(ForgeMediaTokens.Colors.bodySubtle)
                }
            }

            Spacer()

            LanguagePickerView(selection: $confirmed, includeAuto: true)

            if result.needsUserConfirmation {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 11))
                    .foregroundColor(ForgeMediaTokens.Colors.warning)
                    .help("Low confidence — please verify")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            isHovered
            ? ForgeMediaTokens.Colors.secondarySurface
            : ForgeMediaTokens.Colors.canvas
        )
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(
                    result.needsUserConfirmation
                    ? ForgeMediaTokens.Colors.warning.opacity(0.4)
                    : ForgeMediaTokens.Colors.borderSubtle,
                    lineWidth: 1
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
            .font(.system(size: 10, design: .monospaced))
            .foregroundColor(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(color.opacity(0.40), lineWidth: 1)
            )
    }
}
