import SwiftUI
import ForgeMediaUI

struct SettingsView: View {
    private enum SettingsTab: String, CaseIterable, Identifiable {
        case general = "General"
        case privacy = "Privacy"
        case engine = "Engine"

        var id: String { rawValue }
        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .privacy: return "lock.shield"
            case .engine: return "cpu"
            }
        }
    }

    @AppStorage("outputDirectory") private var outputDirectory: String = ""
    @AppStorage("defaultPreset") private var defaultPreset: String = "convert_h264"
    @AppStorage("enableLocalAI") private var enableLocalAI: Bool = false
    @AppStorage("enableRemoteAI") private var enableRemoteAI: Bool = false
    @AppStorage("ffmpegPath") private var ffmpegPath: String = "/opt/homebrew/bin/ffmpeg"
    @AppStorage("maxConcurrentJobs") private var maxConcurrentJobs: Int = 2
    @State private var selectedTab: SettingsTab = .general

    private let ffmpegCandidates = [
        "/opt/homebrew/bin/ffmpeg",
        "/usr/local/bin/ffmpeg",
        "/usr/bin/ffmpeg"
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(ForgeMediaTokens.Colors.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text("ForgeMedia Settings")
                        .font(.system(size: 15).weight(.semibold))
                        .foregroundColor(ForgeMediaTokens.Colors.fg)
                    Text("Local processing defaults, privacy gates, and engine paths")
                        .font(.system(size: 11))
                        .foregroundColor(ForgeMediaTokens.Colors.muted)
                }
                Spacer()
            }
            .padding(18)

            Divider().opacity(0.55)

            HStack(spacing: 8) {
                ForEach(SettingsTab.allCases) { tab in
                    Button {
                        withAnimation(ForgeMediaTokens.Motion.snappy) {
                            selectedTab = tab
                        }
                    } label: {
                        Label(tab.rawValue, systemImage: tab.icon)
                            .font(.system(size: 12).weight(.medium))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 8)
                    .foregroundColor(selectedTab == tab ? ForgeMediaTokens.Colors.accent : ForgeMediaTokens.Colors.fgSecondary)
                    .background(selectedTab == tab ? ForgeMediaTokens.Colors.accentGlow : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            .padding(12)

            Group {
                switch selectedTab {
                case .general: generalTab
                case .privacy: privacyTab
                case .engine: engineTab
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
        }
        .frame(width: 560, height: 420)
        .background(ForgeMediaTokens.Glass.floating)
    }

    private var generalTab: some View {
        VStack(spacing: 10) {
            settingsRow(title: "Output folder", subtitle: outputDirectory.isEmpty ? "Same folder as source" : outputDirectory) {
                Button("Choose…", action: chooseOutputDirectory)
                    .controlSize(.small)
            }

            settingsRow(title: "Default preset", subtitle: "Applied to new jobs unless changed in the toolbar") {
                Picker("Default preset", selection: $defaultPreset) {
                    Text("Convert H.264").tag("convert_h264")
                    Text("Convert HEVC").tag("convert_hevc")
                    Text("Transcribe").tag("transcribe")
                    Text("Dub + Lip-Sync").tag("dub_translate_en")
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 180)
            }

            settingsRow(title: "Max concurrent jobs", subtitle: "Keeps long-form processing responsive") {
                Stepper("\(maxConcurrentJobs)", value: $maxConcurrentJobs, in: 1...4)
                    .frame(width: 90)
            }
        }
    }

    private var privacyTab: some View {
        VStack(spacing: 10) {
            privacyRow(
                icon: "lock.shield.fill",
                iconColor: ForgeMediaTokens.Colors.success,
                title: "Privacy On by default",
                subtitle: "Locked on. No telemetry, cloud uploads, or remote analytics.",
                isFixed: true
            )
            settingsRow(title: "Allow Local AI (Whisper)", subtitle: "Runs entirely on this Mac") {
                Toggle("", isOn: $enableLocalAI)
                    .labelsHidden()
            }

            settingsRow(title: "Allow Remote AI (Gemini)", subtitle: "Disabled by default. Requires explicit consent per workflow.") {
                HStack(spacing: 8) {
                    Text("Sends audio to Google")
                        .font(.system(size: 10, design: .monospaced).weight(.medium))
                        .foregroundColor(ForgeMediaTokens.Colors.warning)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(ForgeMediaTokens.Colors.warningGlow)
                        .clipShape(Capsule(style: .continuous))
                    Toggle("", isOn: $enableRemoteAI)
                        .labelsHidden()
                }
            }
        }
    }

    private var engineTab: some View {
        VStack(spacing: 10) {
            settingsRow(title: "ffmpeg path", subtitle: "Live validation checks whether this executable exists") {
                HStack(spacing: 8) {
                    TextField("/opt/homebrew/bin/ffmpeg", text: $ffmpegPath)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))
                        .frame(width: 250)
                    engineStatusIndicator(path: ffmpegPath)
                }
            }

            settingsRow(title: "Locate ffmpeg", subtitle: "Use the first installed Homebrew or system binary") {
                Button("Locate ffmpeg…") {
                    if let candidate = ffmpegCandidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) {
                        ffmpegPath = candidate
                    }
                }
                .controlSize(.small)
            }

            settingsRow(title: "Build", subtitle: "Local development") {
                Text("1.0.0")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(ForgeMediaTokens.Colors.muted)
            }
        }
    }

    private func privacyRow(icon: String, iconColor: Color, title: String, subtitle: String, isFixed: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.system(size: 18))
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(ForgeMediaTokens.Colors.muted)
            }
            Spacer()
            if isFixed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(ForgeMediaTokens.Colors.success)
                    .font(.system(size: 14))
            }
        }
        .padding(12)
        .forgeGlassCard()
    }

    private func settingsRow<Accessory: View>(title: String, subtitle: String, @ViewBuilder accessory: () -> Accessory) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13).weight(.medium))
                    .foregroundColor(ForgeMediaTokens.Colors.fg)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(ForgeMediaTokens.Colors.muted)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            accessory()
        }
        .padding(12)
        .forgeGlassCard()
    }

    private func engineStatusIndicator(path: String) -> some View {
        let found = FileManager.default.isExecutableFile(atPath: path)
        return Image(systemName: found ? "checkmark.circle.fill" : "xmark.circle.fill")
            .foregroundColor(found ? ForgeMediaTokens.Colors.success : ForgeMediaTokens.Colors.danger)
    }

    private func url(_ path: String) -> URL { URL(fileURLWithPath: path) }

    private func chooseOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Output Folder"
        if panel.runModal() == .OK, let url = panel.url {
            outputDirectory = url.path
        }
    }
}
