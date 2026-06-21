import SwiftUI
import ForgeMediaUI

struct SettingsView: View {
    private enum Tab: String, CaseIterable, Identifiable {
        case general = "General"
        case privacy = "Privacy"
        case engine  = "Engine"

        var id: String { rawValue }
        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .privacy: return "lock.shield"
            case .engine:  return "cpu"
            }
        }
    }

    @AppStorage("outputDirectory")    private var outputDirectory: String  = ""
    @AppStorage("defaultPreset")      private var defaultPreset: String    = "convert_h264"
    @AppStorage("enableLocalAI")      private var enableLocalAI: Bool      = false
    @AppStorage("enableRemoteAI")     private var enableRemoteAI: Bool     = false
    @AppStorage("ffmpegPath")         private var ffmpegPath: String       = "/opt/homebrew/bin/ffmpeg"
    @AppStorage("maxConcurrentJobs")  private var maxConcurrentJobs: Int   = 2
    @AppStorage("folderSuffix")       private var folderSuffix: String     = "_ForgeMedia"
    @AppStorage("fileSuffix")         private var fileSuffix: String       = "_ForgeMedia"

    @State private var selectedTab: Tab = .general

    private let ffmpegCandidates = [
        "/opt/homebrew/bin/ffmpeg",
        "/usr/local/bin/ffmpeg",
        "/usr/bin/ffmpeg"
    ]

    var body: some View {
        VStack(spacing: 0) {
            windowTitleBar
            Divider().overlay(ForgeMediaTokens.Colors.borderDefault)
            tabStrip
            Divider().overlay(ForgeMediaTokens.Colors.borderDefault)
            tabContent
        }
        .frame(width: 580, height: 540)
        .background(ForgeMediaTokens.Colors.canvas)
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
    }

    // MARK: - Title Bar

    private var windowTitleBar: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(ForgeMediaTokens.Colors.secondarySurface)
                    .frame(width: 36, height: 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(ForgeMediaTokens.Colors.borderDefault, lineWidth: 1)
                    )
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ForgeMediaTokens.Colors.heading)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text("Settings")
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundColor(ForgeMediaTokens.Colors.heading)
                Text("Processing defaults · Privacy gates · Engine paths")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(ForgeMediaTokens.Colors.bodySubtle)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(ForgeMediaTokens.Colors.menuBar)
    }

    // MARK: - Tab Strip

    private var tabStrip: some View {
        HStack(spacing: 4) {
            ForEach(Tab.allCases) { tab in
                Button {
                    withAnimation(ForgeMediaTokens.Motion.snappy) { selectedTab = tab }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 11))
                        Text(tab.rawValue)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(
                        selectedTab == tab
                        ? ForgeMediaTokens.Colors.white
                        : ForgeMediaTokens.Colors.body
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 30)
                    .background(
                        selectedTab == tab
                        ? ForgeMediaTokens.Colors.buttonPrimary
                        : Color.clear
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(
                                selectedTab == tab
                                ? ForgeMediaTokens.Colors.borderStrong
                                : ForgeMediaTokens.Colors.borderSubtle,
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
                .animation(ForgeMediaTokens.Motion.snap, value: selectedTab)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(ForgeMediaTokens.Colors.canvas)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        ScrollView {
            VStack(spacing: 8) {
                switch selectedTab {
                case .general: generalTab
                case .privacy: privacyTab
                case .engine:  engineTab
                }
            }
            .padding(16)
        }
    }

    // MARK: - General Tab

    private var generalTab: some View {
        VStack(spacing: 8) {
            settingsRow(title: "Output folder",
                        subtitle: outputDirectory.isEmpty ? "Same folder as source" : outputDirectory) {
                Button(action: chooseOutputDirectory) {
                    Text("Choose…")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ForgeMediaTokens.Colors.heading)
                        .padding(.horizontal, 10)
                        .frame(height: 26)
                        .background(ForgeMediaTokens.Colors.canvas)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(ForgeMediaTokens.Colors.borderDefault, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }

            settingsRow(title: "Default preset",
                        subtitle: "Applied to new jobs unless changed in the toolbar") {
                Menu {
                    ForEach(PresetMeta.all) { meta in
                        Button { defaultPreset = meta.id } label: {
                            Label(meta.name, systemImage: meta.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text(PresetMeta.find(id: defaultPreset)?.name ?? "Select")
                            .font(.system(size: 11))
                            .foregroundColor(ForgeMediaTokens.Colors.heading)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 8))
                            .foregroundColor(ForgeMediaTokens.Colors.bodySubtle)
                    }
                    .padding(.horizontal, 9)
                    .frame(width: 160, height: 26)
                    .background(ForgeMediaTokens.Colors.canvas)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(ForgeMediaTokens.Colors.borderDefault, lineWidth: 1)
                    )
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }

            settingsRow(title: "Max concurrent jobs",
                        subtitle: "Keeps long-form processing from saturating the system") {
                HStack(spacing: 0) {
                    Button {
                        if maxConcurrentJobs > 1 { maxConcurrentJobs -= 1 }
                    } label: {
                        Text("−")
                            .font(.system(size: 13))
                            .foregroundColor(ForgeMediaTokens.Colors.heading)
                            .frame(width: 26, height: 26)
                            .background(ForgeMediaTokens.Colors.menuBar)
                            .clipShape(
                                UnevenRoundedRectangle(
                                    topLeadingRadius: 3, bottomLeadingRadius: 3,
                                    bottomTrailingRadius: 0, topTrailingRadius: 0
                                )
                            )
                    }
                    .buttonStyle(.plain)
                    Text("\(maxConcurrentJobs)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(ForgeMediaTokens.Colors.heading)
                        .frame(width: 30, height: 26)
                        .background(ForgeMediaTokens.Colors.inputBg)
                    Button {
                        if maxConcurrentJobs < 4 { maxConcurrentJobs += 1 }
                    } label: {
                        Text("+")
                            .font(.system(size: 13))
                            .foregroundColor(ForgeMediaTokens.Colors.heading)
                            .frame(width: 26, height: 26)
                            .background(ForgeMediaTokens.Colors.menuBar)
                            .clipShape(
                                UnevenRoundedRectangle(
                                    topLeadingRadius: 0, bottomLeadingRadius: 0,
                                    bottomTrailingRadius: 3, topTrailingRadius: 3
                                )
                            )
                    }
                    .buttonStyle(.plain)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(ForgeMediaTokens.Colors.borderDefault, lineWidth: 1)
                )
            }

            // Output Naming section
            sectionHeader("Output Naming")

            settingsRow(title: "Folder suffix",
                        subtitle: "Appended to each output folder  e.g. Videos_ForgeMedia") {
                TextField("_ForgeMedia", text: $folderSuffix)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11, design: .monospaced))
                    .frame(width: 150)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(ForgeMediaTokens.Colors.borderDefault, lineWidth: 1)
                    )
            }

            settingsRow(title: "File suffix",
                        subtitle: "Appended to each output filename  e.g. clip_ForgeMedia.mp4") {
                TextField("_ForgeMedia", text: $fileSuffix)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11, design: .monospaced))
                    .frame(width: 150)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(ForgeMediaTokens.Colors.borderDefault, lineWidth: 1)
                    )
            }
        }
    }

    // MARK: - Privacy Tab

    private var privacyTab: some View {
        VStack(spacing: 8) {
            privacyRow(
                icon: "lock.shield.fill",
                iconColor: ForgeMediaTokens.Colors.success,
                title: "Privacy On by default",
                subtitle: "Locked on. No telemetry, cloud uploads, or remote analytics.",
                isFixed: true
            )
            settingsRow(title: "Allow Local AI (Whisper)",
                        subtitle: "Runs entirely on this Mac — no data leaves your system") {
                Toggle("", isOn: $enableLocalAI).labelsHidden()
                    .tint(ForgeMediaTokens.Colors.brand)
            }
            settingsRow(title: "Allow Remote AI (Gemini)",
                        subtitle: "Disabled by default. Requires explicit consent per workflow.") {
                HStack(spacing: 8) {
                    Text("SENDS AUDIO TO GOOGLE")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(ForgeMediaTokens.Colors.warning)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(ForgeMediaTokens.Colors.warningSoft)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(ForgeMediaTokens.Colors.warning.opacity(0.5), lineWidth: 1)
                        )
                    Toggle("", isOn: $enableRemoteAI).labelsHidden()
                        .tint(ForgeMediaTokens.Colors.brand)
                }
            }
        }
    }

    // MARK: - Engine Tab

    private var engineTab: some View {
        VStack(spacing: 8) {
            settingsRow(title: "ffmpeg path",
                        subtitle: "Live validation checks whether this executable exists") {
                HStack(spacing: 8) {
                    TextField("/opt/homebrew/bin/ffmpeg", text: $ffmpegPath)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))
                        .frame(width: 230)
                    engineStatusDot(path: ffmpegPath)
                }
            }

            settingsRow(title: "Locate ffmpeg",
                        subtitle: "Use the first installed Homebrew or system binary") {
                Button("Locate…") {
                    if let candidate = ffmpegCandidates.first(where: {
                        FileManager.default.isExecutableFile(atPath: $0)
                    }) {
                        ffmpegPath = candidate
                    }
                }
                .buttonStyle(ForgeButtonStyle(.outline))
                .controlSize(.small)
            }

            settingsRow(title: "Build", subtitle: "Local development") {
                Text("1.0.0")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(ForgeMediaTokens.Colors.bodySubtle)
            }
        }
    }

    // MARK: - Row Components

    private func settingsRow<A: View>(
        title: String, subtitle: String, @ViewBuilder accessory: () -> A
    ) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ForgeMediaTokens.Colors.heading)
                Text(subtitle)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(ForgeMediaTokens.Colors.bodySubtle)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            accessory()
        }
        .padding(12)
        .background(ForgeMediaTokens.Colors.canvas)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(ForgeMediaTokens.Colors.borderSubtle, lineWidth: 1)
        )
    }

    private func privacyRow(icon: String, iconColor: Color, title: String, subtitle: String, isFixed: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.system(size: 16))
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ForgeMediaTokens.Colors.heading)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(ForgeMediaTokens.Colors.bodySubtle)
            }
            Spacer()
            if isFixed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(ForgeMediaTokens.Colors.success)
                    .font(.system(size: 14))
            }
        }
        .padding(12)
        .background(ForgeMediaTokens.Colors.successSoft)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(ForgeMediaTokens.Colors.success.opacity(0.3), lineWidth: 1)
        )
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack(spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .tracking(1.2)
                .foregroundColor(ForgeMediaTokens.Colors.bodySubtle)
            Rectangle()
                .fill(ForgeMediaTokens.Colors.borderSubtle)
                .frame(height: 1)
        }
        .padding(.top, 4)
    }

    private func engineStatusDot(path: String) -> some View {
        let found = FileManager.default.isExecutableFile(atPath: path)
        return Image(systemName: found ? "checkmark.circle.fill" : "xmark.circle.fill")
            .foregroundColor(found ? ForgeMediaTokens.Colors.success : ForgeMediaTokens.Colors.danger)
            .font(.system(size: 14))
    }

    private func chooseOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false; panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false; panel.prompt = "Select Output Folder"
        if panel.runModal() == .OK, let url = panel.url {
            outputDirectory = url.path
        }
    }
}
