import SwiftUI
import AppKit
import ForgeMediaDomain
import ForgeMediaUI

/// Main window showing the job queue with drag/drop intake and a live activity stream.
@MainActor
struct MainWindow: View {
    @State private var model: AppModel
    @State private var isDragTargeted = false
    @State private var selectedPreset: String = "convert_h264"
    @State private var showSettings = false
    @State private var hoveredIntakeAction: String?
    @State private var showActivityStream: Bool = true

    init(model: AppModel) {
        self.model = model
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("ForgeMedia")
                    .font(.system(size: 15, design: .default).weight(.semibold))
                    .foregroundColor(ForgeMediaTokens.Colors.fg)

                Spacer()

                // Privacy badge
                privacyBadge

                // Preset picker
                Picker("Preset", selection: $selectedPreset) {
                    ForEach(model.presets) { p in
                        Text(p.name).tag(p.id)
                    }
                }
                .frame(width: 140)
                .controlSize(.small)

                Button("Select Video") {
                    pickSingleVideo()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut("o", modifiers: [.command])
                .help("Select one video (⌘O)")
                .onHover { hovering in
                    hoveredIntakeAction = hovering ? "single" : nil
                }

                Button("Select Videos") {
                    pickMultipleVideos()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut("o", modifiers: [.command, .shift])
                .help("Select multiple videos (⇧⌘O)")
                .onHover { hovering in
                    hoveredIntakeAction = hovering ? "multi" : nil
                }

                Button("Select Folder") {
                    pickFolderRecursive()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("f", modifiers: [.command, .shift])
                .help("Select folder recursively (⇧⌘F)")
                .onHover { hovering in
                    hoveredIntakeAction = hovering ? "folder" : nil
                }

                Button {
                    showSettings.toggle()
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)
                .keyboardShortcut(",", modifiers: [.command])
                .help("Open settings (⌘,)")

                Button {
                    withAnimation(ForgeMediaTokens.Motion.smooth) {
                        showActivityStream.toggle()
                    }
                } label: {
                    Image(systemName: showActivityStream ? "sidebar.right" : "sidebar.squares.right")
                }
                .buttonStyle(.borderless)
                .keyboardShortcut("\\", modifiers: [.command])
                .help("Toggle activity stream (⌘\\)")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(ForgeMediaTokens.Glass.base)

            // Language detection progress banner
            if model.isDetectingLanguages {
                HStack(spacing: 10) {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 16, height: 16)
                    Text("Detecting source languages… · \(model.pendingURLs.count) file\(model.pendingURLs.count == 1 ? "" : "s")")
                        .font(.system(size: 13, design: .default).weight(.medium))
                        .foregroundColor(ForgeMediaTokens.Colors.fgSecondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(ForgeMediaTokens.Colors.accentGlow)
                .transition(.opacity.animation(ForgeMediaTokens.Motion.smooth))
            }

            Divider()

            // Content: NavigationSplitView for proper Apple HIG multi-column layout
            NavigationSplitView(columnVisibility: .constant(.all)) {
                // SIDEBAR: job queue / empty state
                Group {
                    if model.jobs.isEmpty {
                        VStack(spacing: 16) {
                            DropZoneView(isTargeted: $isDragTargeted) { urls in
                                model.intakeVideos(urls: urls, presetID: selectedPreset)
                            }
                            .frame(width: 400)

                            Text("Drop media files, or choose a file to get started")
                                .font(.body)
                                .foregroundColor(ForgeMediaTokens.Colors.muted)
                                .multilineTextAlignment(.center)

                            Text(intakeHintText)
                                .font(.system(.caption, design: .rounded).weight(.medium))
                                .foregroundColor(ForgeMediaTokens.Colors.fgSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(ForgeMediaTokens.Colors.borderSoft)
                                .clipShape(Capsule(style: .continuous))
                                .animation(ForgeMediaTokens.Motion.snappy, value: intakeHintText)

                            Button {
                                runVisualDemo()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "play.rectangle.fill")
                                    Text("Try a visual demo")
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .help("Seeds a synthetic job so you can see the activity stream")
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Job queue
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                DropZoneView(isTargeted: $isDragTargeted) { urls in
                                    model.intakeVideos(urls: urls, presetID: selectedPreset)
                                }
                                .frame(height: isDragTargeted ? 120 : 60)
                                .padding(.vertical, 8)

                                ForEach(model.jobs) { job in
                                    JobCardView(
                                        job: job,
                                        preset: model.presets.first(where: { $0.id == job.presetID }),
                                        onPause: {},
                                        onCancel: { Task { await model.cancelJob(job) } },
                                        onRetry: {
                                            Task {
                                                var retryJob = job
                                                retryJob = retryJob.with(phase: .idle, progressFraction: 0, progressLabel: "Retrying…")
                                                await model.startJob(retryJob)
                                            }
                                        },
                                        onOpenOutput: {
                                            if let output = job.outputURL {
                                                NSWorkspace.shared.open(output)
                                            }
                                        }
                                    )
                                    .transition(
                                        .asymmetric(
                                            insertion: .opacity.combined(with: .scale(scale: 0.98)).animation(ForgeMediaTokens.Motion.cardEnter),
                                            removal: .opacity.animation(ForgeMediaTokens.Motion.smooth)
                                        )
                                    )
                                }
                            }
                            .padding(.vertical, 12)
                        }
                        .navigationSplitViewColumnWidth(min: 420, ideal: 520)
                    }
                }
            } detail: {
                // DETAIL: live activity stream (right pane)
                ActivityStreamView(events: model.events, jobs: model.jobs)
                    .frame(minWidth: 320)
                    .padding(12)
                    .navigationSplitViewColumnWidth(min: 340, ideal: 400)
            }
        }
        .background(ForgeMediaTokens.Colors.bg)
        .frame(minWidth: 980, minHeight: 640)
        .animation(ForgeMediaTokens.Motion.smooth, value: model.jobs.count)
        .sheet(isPresented: $model.showLanguageSheet) {
            LanguageDetectionSheet(
                detectionResults: model.detectionResults,
                onConfirm: { overrides, targetLanguage in
                    model.confirmLanguagesAndStart(overrides: overrides, targetLanguage: targetLanguage)
                },
                onCancel: {
                    model.cancelPendingDetection()
                }
            )
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear {
            model.start()
        }
    }

    // MARK: - Sub-views

    private var privacyBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: model.privacyMode == .privacyOn ? "lock.shield.fill" : "lock.open")
                .font(.system(size: 10))
            Text(model.privacyMode == .privacyOn ? "Privacy On" : "Local Only")
                .font(.system(size: 10, design: .monospaced).weight(.medium))
        }
        .foregroundColor(model.privacyMode == .privacyOn ? ForgeMediaTokens.Colors.success : ForgeMediaTokens.Colors.warning)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(ForgeMediaTokens.Colors.borderSoft)
        .clipShape(Capsule(style: .continuous))
    }

    private var intakeHintText: String {
        switch hoveredIntakeAction {
        case "single":
            return "Process one selected video"
        case "multi":
            return "Process only selected videos"
        case "folder":
            return "Process all videos in selected folder recursively"
        default:
            return "Single, multi-select, and recursive folder modes are ready"
        }
    }

    // MARK: - File pickers

    private func pickSingleVideo() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.movie]
        if panel.runModal() == .OK, let url = panel.url {
            model.intakeVideo(url: url, presetID: selectedPreset)
        }
    }

    private func pickMultipleVideos() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.movie]
        if panel.runModal() == .OK {
            model.intakeVideos(urls: panel.urls, presetID: selectedPreset)
        }
    }

    private func pickFolderRecursive() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let folderURL = panel.url {
            model.intakeFolder(folderURL: folderURL, recursive: true, presetID: selectedPreset)
        }
    }
}

// MARK: - Demo seeding (visual review)

extension MainWindow {
    func runVisualDemo() {
        let demoURL = URL(fileURLWithPath: "/tmp/forgemedia_demo_interview_4k.mov")
        model.addJob(url: demoURL, presetID: selectedPreset)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak model] in
            model?.injectDemoActivity()
        }
    }
}
