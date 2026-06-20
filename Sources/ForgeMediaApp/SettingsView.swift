import SwiftUI
import ForgeMediaUI

struct SettingsView: View {
    @AppStorage("outputDirectory") private var outputDirectory: String = ""
    @AppStorage("defaultPreset") private var defaultPreset: String = "convert_h264"
    @AppStorage("enableLocalAI") private var enableLocalAI: Bool = false
    @AppStorage("enableRemoteAI") private var enableRemoteAI: Bool = false
    @AppStorage("ffmpegPath") private var ffmpegPath: String = "/opt/homebrew/bin/ffmpeg"
    @AppStorage("maxConcurrentJobs") private var maxConcurrentJobs: Int = 2

    private let ffmpegCandidates = [
        "/opt/homebrew/bin/ffmpeg",
        "/usr/local/bin/ffmpeg",
        "/usr/bin/ffmpeg"
    ]

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("General", systemImage: "gearshape") }
            privacyTab
                .tabItem { Label("Privacy", systemImage: "lock.shield") }
            engineTab
                .tabItem { Label("Engine", systemImage: "cpu") }
        }
        .frame(width: 460, height: 360)
        .background(ForgeMediaTokens.Colors.bg)
    }

    private var generalTab: some View {
        Form {
            Section("Output") {
                HStack {
                    Text("Output folder")
                        .frame(width: 120, alignment: .trailing)
                    TextField("Same folder as source", text: $outputDirectory)
                        .textFieldStyle(.roundedBorder)
                    Button("Choose…") {
                        chooseOutputDirectory()
                    }
                    .controlSize(.small)
                }

                HStack {
                    Text("Default preset")
                        .frame(width: 120, alignment: .trailing)
                    Picker("", selection: $defaultPreset) {
                        Text("Convert H.264").tag("convert_h264")
                        Text("Convert H.265").tag("convert_h265")
                        Text("Extract Audio").tag("extract_audio")
                        Text("Add Subtitles").tag("add_subtitles")
                    }
                    .pickerStyle(.menu)
                    .frame(width: 180)
                }

                HStack {
                    Text("Concurrent jobs")
                        .frame(width: 120, alignment: .trailing)
                    Picker("", selection: $maxConcurrentJobs) {
                        Text("1").tag(1)
                        Text("2").tag(2)
                        Text("4").tag(4)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var privacyTab: some View {
        Form {
            Section("Privacy") {
                privacyRow(
                    icon: "lock.shield.fill",
                    iconColor: ForgeMediaTokens.Colors.success,
                    title: "Privacy On by default",
                    subtitle: "No telemetry, no cloud uploads, no remote analytics",
                    isFixed: true
                )
                privacyRow(
                    icon: "network.slash",
                    iconColor: ForgeMediaTokens.Colors.success,
                    title: "Remote crash reports disabled",
                    subtitle: "Diagnostics stay on your Mac",
                    isFixed: true
                )
            }
            Section("AI Features (opt-in)") {
                Toggle(isOn: $enableLocalAI) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Local AI (Whisper / Ollama)")
                            .font(.body)
                        Text("Runs entirely on-device via Core ML or llama.cpp")
                            .font(.caption)
                            .foregroundColor(ForgeMediaTokens.Colors.muted)
                    }
                }
                Toggle(isOn: $enableRemoteAI) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Remote AI")
                            .font(.body)
                        Text("Sends data to an external API — disabled by default")
                            .font(.caption)
                            .foregroundColor(enableRemoteAI ? ForgeMediaTokens.Colors.warning : ForgeMediaTokens.Colors.muted)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var engineTab: some View {
        Form {
            Section("FFmpeg") {
                HStack {
                    Text("ffmpeg path")
                        .frame(width: 100, alignment: .trailing)
                    TextField("/opt/homebrew/bin/ffmpeg", text: $ffmpegPath)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                    engineStatusIndicator(path: ffmpegPath)
                }
                HStack {
                    Spacer()
                    ForEach(ffmpegCandidates, id: \.self) { candidate in
                        let found = FileManager.default.isExecutableFile(atPath: candidate)
                        if found {
                            Button("Use \(url(candidate).lastPathComponent) (\(candidate))") {
                                ffmpegPath = candidate
                            }
                            .controlSize(.mini)
                            .buttonStyle(.borderless)
                            .foregroundColor(ForgeMediaTokens.Colors.accent)
                        }
                    }
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                        .foregroundColor(ForgeMediaTokens.Colors.muted)
                    Spacer()
                    Text("1.0.0")
                        .font(.system(.body, design: .monospaced))
                }
                HStack {
                    Text("Build")
                        .foregroundColor(ForgeMediaTokens.Colors.muted)
                    Spacer()
                    Text("Local development")
                        .font(.system(.body, design: .monospaced))
                }
            }
        }
        .formStyle(.grouped)
        .padding()
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
        .padding(.vertical, 2)
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
