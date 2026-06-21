import SwiftUI
import AppKit
import ForgeMediaDomain
import ForgeMediaUI

/// Main window — retro macOS desktop workspace.
///
/// Layout (top to bottom):
///   36px menu-bar strip (cream/espresso · job stats · privacy · gear)
///   32px action strip (preset picker · file-select buttons)
///   [optional] detection banner
///   content HStack: job queue (fluid) | 1px divider | activity stream (360px)
@MainActor
struct MainWindow: View {
    @State private var model: AppModel
    @State private var isDragTargeted = false
    @State private var selectedPreset: String = "convert_h264"
    @State private var showSettings = false
    @State private var showPresetDrop = false

    init(model: AppModel) {
        self.model = model
    }

    var body: some View {
        VStack(spacing: 0) {
            menuBarStrip
            thinRule
            actionStrip
            thinRule

            if model.isDetectingLanguages {
                detectionBanner
                thinRule
            }

            HStack(spacing: 0) {
                Group {
                    if model.jobs.isEmpty { emptyState } else { jobQueue }
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(ForgeMediaTokens.Colors.borderDefault)
                    .frame(width: 1)

                ActivityStreamView(events: model.events, jobs: model.jobs)
                    .frame(width: 360)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(ForgeMediaTokens.Colors.canvas)
        .frame(minWidth: 980, minHeight: 640)
        .animation(ForgeMediaTokens.Motion.smooth, value: model.jobs.count)
        .sheet(isPresented: $model.showLanguageSheet) {
            LanguageDetectionSheet(
                detectionResults: model.detectionResults,
                onConfirm: { overrides, targetLanguage in
                    model.confirmLanguagesAndStart(overrides: overrides, targetLanguage: targetLanguage)
                },
                onCancel: { model.cancelPendingDetection() }
            )
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear {
            model.start()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                guard let window = NSApp.windows.first(where: { !$0.canBecomeKey == false })
                        ?? NSApp.windows.first else { return }
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
                window.isMovableByWindowBackground = true
            }
        }
    }

    // MARK: - Menu Bar Strip (36px)

    private var menuBarStrip: some View {
        HStack(spacing: 8) {
            // App logo mark
            HStack(spacing: 5) {
                Image(systemName: "film.stack.fill")
                    .font(.system(size: 11, weight: .semibold))
                Text("FM")
                    .font(.system(size: 12, weight: .semibold, design: .serif))
            }
            .foregroundColor(ForgeMediaTokens.Colors.heading)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(ForgeMediaTokens.Colors.canvas)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(ForgeMediaTokens.Colors.borderDefault, lineWidth: 1)
            )

            Text("FORGEMEDIA")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .tracking(1.5)
                .foregroundColor(ForgeMediaTokens.Colors.heading)

            Rectangle()
                .fill(ForgeMediaTokens.Colors.borderSubtle)
                .frame(width: 1, height: 14)

            // Job stat chips
            jobStatChip(
                count: model.activeJobCount,
                label: "RUNNING",
                accent: model.activeJobCount > 0 ? ForgeMediaTokens.Colors.brand : nil
            )
            jobStatChip(
                count: model.jobs.filter { $0.phase == .completed || $0.phase == .completedWithWarnings }.count,
                label: "DONE",
                accent: nil
            )
            let failed = model.jobs.filter { $0.phase == .failed }.count
            if failed > 0 {
                jobStatChip(count: failed, label: "FAILED", accent: ForgeMediaTokens.Colors.danger)
            }

            Spacer()

            privacyBadge

            iconButton(systemName: "gearshape", help: "Settings (⌘,)") {
                showSettings.toggle()
            }
            .keyboardShortcut(",", modifiers: .command)
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(ForgeMediaTokens.Colors.menuBar)
    }

    // MARK: - Action Strip (32px)

    private var actionStrip: some View {
        HStack(spacing: 8) {
            // Preset picker
            ZStack(alignment: .topLeading) {
                Button {
                    withAnimation(ForgeMediaTokens.Motion.snap) { showPresetDrop.toggle() }
                } label: {
                    HStack(spacing: 5) {
                        Text(currentPresetName.uppercased())
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(ForgeMediaTokens.Colors.heading)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        Image(systemName: showPresetDrop ? "chevron.up" : "chevron.down")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(ForgeMediaTokens.Colors.bodySubtle)
                    }
                    .padding(.horizontal, 10)
                    .frame(width: 170, height: 28)
                    .background(ForgeMediaTokens.Colors.canvas)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(ForgeMediaTokens.Colors.borderDefault, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                if showPresetDrop {
                    VStack(spacing: 0) {
                        ForEach(Array(model.presets.enumerated()), id: \.element.id) { idx, p in
                            Button {
                                withAnimation(ForgeMediaTokens.Motion.snap) {
                                    selectedPreset = p.id
                                    showPresetDrop = false
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 9))
                                        .opacity(p.id == selectedPreset ? 1 : 0)
                                        .foregroundColor(ForgeMediaTokens.Colors.brand)
                                    Text(p.name)
                                        .font(.system(size: 11))
                                        .foregroundColor(ForgeMediaTokens.Colors.heading)
                                    Spacer()
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(
                                    p.id == selectedPreset
                                    ? ForgeMediaTokens.Colors.brandSofter
                                    : ForgeMediaTokens.Colors.canvas
                                )
                            }
                            .buttonStyle(.plain)
                            if idx < model.presets.count - 1 {
                                Divider().overlay(ForgeMediaTokens.Colors.borderSubtle)
                            }
                        }
                    }
                    .frame(width: 210)
                    .background(ForgeMediaTokens.Colors.canvas)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(ForgeMediaTokens.Colors.borderDefault, lineWidth: 1)
                    )
                    .shadow(
                        color: ForgeMediaTokens.Shadow.menu.color,
                        radius: ForgeMediaTokens.Shadow.menu.radius,
                        x: 0, y: ForgeMediaTokens.Shadow.menu.y
                    )
                    .offset(y: 32)
                    .zIndex(100)
                }
            }
            .frame(width: 170, height: 28, alignment: .topLeading)

            Rectangle()
                .fill(ForgeMediaTokens.Colors.borderSubtle)
                .frame(width: 1, height: 16)

            Button("Select Video") { pickSingleVideo() }
                .buttonStyle(ForgeButtonStyle(.outline))
                .keyboardShortcut("o", modifiers: .command)
                .help("Select one video (⌘O)")

            Button("Select Videos") { pickMultipleVideos() }
                .buttonStyle(ForgeButtonStyle(.outline))
                .keyboardShortcut("o", modifiers: [.command, .shift])
                .help("Select multiple videos (⇧⌘O)")

            Button("Select Folder") { pickFolderRecursive() }
                .buttonStyle(ForgeButtonStyle(.secondary))
                .keyboardShortcut("f", modifiers: [.command, .shift])
                .help("Select folder recursively (⇧⌘F)")

            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(height: 46)
        .background(ForgeMediaTokens.Colors.canvas)
    }

    // MARK: - Detection Banner

    private var detectionBanner: some View {
        HStack(spacing: 10) {
            ProgressView().scaleEffect(0.7).frame(width: 14, height: 14)
            Text("Detecting languages…")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(ForgeMediaTokens.Colors.heading)
            Text("·")
                .foregroundColor(ForgeMediaTokens.Colors.borderDefault)
            Text("\(model.pendingURLs.count) file\(model.pendingURLs.count == 1 ? "" : "s") queued")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(ForgeMediaTokens.Colors.bodySubtle)
            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(ForgeMediaTokens.Colors.warningSoft)
        .transition(.opacity.animation(ForgeMediaTokens.Motion.smooth))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ZStack {
            ForgeMediaTokens.Colors.canvas

            VStack(spacing: 24) {
                DropZoneView(isTargeted: $isDragTargeted) { urls in
                    model.intakeVideos(urls: urls, presetID: selectedPreset)
                }
                .frame(width: 440, height: 190)

                // Keyboard shortcuts
                HStack(spacing: 12) {
                    shortcutHint(key: "⌘O",  label: "One video")
                    shortcutHint(key: "⇧⌘O", label: "Multiple")
                    shortcutHint(key: "⇧⌘F", label: "Folder")
                }

                // Status bar
                HStack(spacing: 6) {
                    Text("0 active workers · 0 jobs queued · LOCAL ENGINE")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(ForgeMediaTokens.Colors.bodySubtle)
                    Text("·")
                        .foregroundColor(ForgeMediaTokens.Colors.borderDefault)
                    Text("/usr/bin/ffmpeg")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(ForgeMediaTokens.Colors.bodySubtle)
                }

                Button {
                    runVisualDemo()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.circle")
                            .font(.system(size: 11))
                        Text("Try a visual demo")
                    }
                }
                .buttonStyle(ForgeButtonStyle(.ghost))
                .help("Seeds a synthetic job to preview the activity stream")
            }
            .padding(40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func shortcutHint(key: String, label: String) -> some View {
        HStack(spacing: 6) {
            Text(key)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(ForgeMediaTokens.Colors.heading)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(ForgeMediaTokens.Colors.menuBar)
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(ForgeMediaTokens.Colors.borderDefault, lineWidth: 1)
                )
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(ForgeMediaTokens.Colors.bodySubtle)
        }
    }

    // MARK: - Job Queue

    private var jobQueue: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                DropZoneView(isTargeted: $isDragTargeted) { urls in
                    model.intakeVideos(urls: urls, presetID: selectedPreset)
                }
                .frame(height: isDragTargeted ? 90 : 44)
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .animation(ForgeMediaTokens.Motion.spring, value: isDragTargeted)

                ForEach(model.jobs) { job in
                    JobCardView(
                        job: job,
                        preset: model.presets.first(where: { $0.id == job.presetID }),
                        onPause: {},
                        onCancel: { Task { await model.cancelJob(job) } },
                        onRetry: {
                            Task {
                                let retryJob = job.with(phase: .idle, progressFraction: 0, progressLabel: "Retrying…")
                                await model.startJob(retryJob)
                            }
                        },
                        onOpenOutput: {
                            if let output = job.outputURL {
                                NSWorkspace.shared.activateFileViewerSelecting([output])
                            }
                        }
                    )
                    .transition(
                        .asymmetric(
                            insertion: .opacity.combined(with: .offset(y: 8))
                                .animation(ForgeMediaTokens.Motion.cardEnter),
                            removal: .opacity.animation(ForgeMediaTokens.Motion.smooth)
                        )
                    )
                }
            }
            .padding(.bottom, 14)
        }
        .background(ForgeMediaTokens.Colors.canvas)
    }

    // MARK: - Helpers

    private var currentPresetName: String {
        model.presets.first { $0.id == selectedPreset }?.name ?? "Preset"
    }

    private var privacyBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: model.privacyMode == .privacyOn ? "lock.fill" : "lock.open")
                .font(.system(size: 9))
            Text(model.privacyMode == .privacyOn ? "LOCAL" : "ONLINE")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .tracking(0.5)
        }
        .foregroundColor(
            model.privacyMode == .privacyOn
            ? ForgeMediaTokens.Colors.success
            : ForgeMediaTokens.Colors.warning
        )
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            model.privacyMode == .privacyOn
            ? ForgeMediaTokens.Colors.successSoft
            : ForgeMediaTokens.Colors.warningSoft
        )
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(
                    model.privacyMode == .privacyOn
                    ? ForgeMediaTokens.Colors.success.opacity(0.5)
                    : ForgeMediaTokens.Colors.warning.opacity(0.5),
                    lineWidth: 1
                )
        )
    }

    private func jobStatChip(count: Int, label: String, accent: Color?) -> some View {
        HStack(spacing: 4) {
            if let a = accent {
                Circle().fill(a).frame(width: 6, height: 6)
            }
            Text("\(count)")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(ForgeMediaTokens.Colors.heading)
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .tracking(0.5)
                .foregroundColor(ForgeMediaTokens.Colors.bodySubtle)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(ForgeMediaTokens.Colors.canvas)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(ForgeMediaTokens.Colors.borderSubtle, lineWidth: 1)
        )
    }

    private func iconButton(systemName: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(ForgeMediaTokens.Colors.bodySubtle)
                .frame(width: 28, height: 28)
                .background(ForgeMediaTokens.Colors.canvas)
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(ForgeMediaTokens.Colors.borderDefault, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .help(help)
    }

    private var thinRule: some View {
        Rectangle()
            .fill(ForgeMediaTokens.Colors.borderDefault)
            .frame(height: 1)
    }

    // MARK: - File Pickers

    private func pickSingleVideo() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true; panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false; panel.allowedContentTypes = [.movie]
        if panel.runModal() == .OK, let url = panel.url {
            model.intakeVideo(url: url, presetID: selectedPreset)
        }
    }

    private func pickMultipleVideos() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true; panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true; panel.allowedContentTypes = [.movie]
        if panel.runModal() == .OK { model.intakeVideos(urls: panel.urls, presetID: selectedPreset) }
    }

    private func pickFolderRecursive() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false; panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            model.intakeFolder(folderURL: url, recursive: true, presetID: selectedPreset)
        }
    }
}

// MARK: - Demo

extension MainWindow {
    func runVisualDemo() {
        let demoURL = URL(fileURLWithPath: "/tmp/forgemedia_demo_interview_4k.mov")
        model.addJob(url: demoURL, presetID: selectedPreset)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak model] in
            model?.injectDemoActivity()
        }
    }
}
