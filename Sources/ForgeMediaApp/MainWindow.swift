import SwiftUI
import AppKit
import ForgeMediaDomain
import ForgeMediaUI

/// Main window — neo-brutalist styled.
///
/// Visual language: cream canvas with grid texture · bordered logo sticker ·
/// heavy 3px rule dividers · neo push-down buttons · loud uppercase labels.
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
            toolbar

            // Language detection progress banner
            if model.isDetectingLanguages {
                detectionBanner
            }

            // Heavy rule separator
            Rectangle()
                .fill(Color.black)
                .frame(height: 3)

            NavigationSplitView(columnVisibility: .constant(.all)) {
                // SIDEBAR: job queue / empty state
                Group {
                    if model.jobs.isEmpty {
                        emptyState
                    } else {
                        jobQueue
                    }
                }
            } detail: {
                // DETAIL: live activity stream (right pane)
                ActivityStreamView(events: model.events, jobs: model.jobs)
                    .frame(minWidth: 320)
                    .padding(16)
                    .navigationSplitViewColumnWidth(min: 340, ideal: 400)
            }
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

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 10) {
            // ── Logo sticker ──────────────────────────────────────────────────
            // Yellow box with black border — the visual anchor for the toolbar.
            HStack(spacing: 6) {
                Image(systemName: "film.stack.fill")
                    .font(.system(size: 12, weight: .black))
                Text("FORGEMEDIA")
                    .font(.system(size: 12, weight: .black))
                    .tracking(1.5)
            }
            .foregroundColor(.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(ForgeMediaTokens.Colors.secondary)
            .clipShape(Rectangle())
            .overlay(Rectangle().stroke(Color.black, lineWidth: 3))
            .shadow(color: .black, radius: 0, x: 3, y: 3)
            .rotationEffect(.degrees(-1)) // sticker tilt

            Spacer()

            // ── Privacy badge ─────────────────────────────────────────────────
            privacyBadge

            // ── Preset picker ─────────────────────────────────────────────────
            Picker("Preset", selection: $selectedPreset) {
                ForEach(model.presets) { p in
                    Text(p.name.uppercased()).tag(p.id)
                }
            }
            .frame(width: 160)
            .controlSize(.small)

            // ── Intake buttons ────────────────────────────────────────────────
            Button("SELECT VIDEO") {
                pickSingleVideo()
            }
            .buttonStyle(NeoBrutalButtonStyle(.outline))
            .keyboardShortcut("o", modifiers: [.command])
            .help("Select one video (⌘O)")
            .onHover { hoveredIntakeAction = $0 ? "single" : nil }

            Button("SELECT VIDEOS") {
                pickMultipleVideos()
            }
            .buttonStyle(NeoBrutalButtonStyle(.outline))
            .keyboardShortcut("o", modifiers: [.command, .shift])
            .help("Select multiple videos (⇧⌘O)")
            .onHover { hoveredIntakeAction = $0 ? "multi" : nil }

            Button("SELECT FOLDER") {
                pickFolderRecursive()
            }
            .buttonStyle(NeoBrutalButtonStyle(.secondary))
            .keyboardShortcut("f", modifiers: [.command, .shift])
            .help("Select folder recursively (⇧⌘F)")
            .onHover { hoveredIntakeAction = $0 ? "folder" : nil }

            // ── Icon buttons ──────────────────────────────────────────────────
            toolbarIconButton(
                systemName: "gearshape.fill",
                help: "Open settings (⌘,)"
            ) {
                showSettings.toggle()
            }
            .keyboardShortcut(",", modifiers: [.command])

            toolbarIconButton(
                systemName: showActivityStream ? "sidebar.right" : "sidebar.squares.right",
                help: "Toggle activity stream (⌘\\)"
            ) {
                withAnimation(ForgeMediaTokens.Motion.smooth) {
                    showActivityStream.toggle()
                }
            }
            .keyboardShortcut("\\", modifiers: [.command])
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(ForgeMediaTokens.Colors.canvas.forgeGridTexture(cellSize: 28, opacity: 0.05))
    }

    private var detectionBanner: some View {
        HStack(spacing: 10) {
            // Bordered spinner label
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.7)
                    .frame(width: 16, height: 16)
                Text("DETECTING LANGUAGES")
                    .font(.system(size: 11, weight: .black))
                    .tracking(2)
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(ForgeMediaTokens.Colors.neomuted)
            .clipShape(Rectangle())
            .overlay(Rectangle().stroke(Color.black, lineWidth: 2))

            Text("·")
                .font(.system(size: 12, weight: .black))
                .foregroundColor(.black.opacity(0.40))

            Text("\(model.pendingURLs.count) file\(model.pendingURLs.count == 1 ? "" : "s") queued")
                .font(.system(.caption, design: .default).weight(.bold))
                .foregroundColor(.black.opacity(0.65))

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(ForgeMediaTokens.Colors.neomuted.opacity(0.40))
        .overlay(Rectangle().stroke(Color.black, lineWidth: 2))
        .transition(.opacity.animation(ForgeMediaTokens.Motion.smooth))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ZStack {
            // Halftone dot texture — fills the empty state area
            ForgeMediaTokens.Colors.canvas
            HalftonePatternView(dotSize: 1.5, spacing: 22, dotOpacity: 0.06)

            VStack(spacing: 20) {
                DropZoneView(isTargeted: $isDragTargeted) { urls in
                    model.intakeVideos(urls: urls, presetID: selectedPreset)
                }
                .frame(width: 400)

                // Hint tag — rotated sticker
                Text(intakeHintText.uppercased())
                    .font(.system(.caption, design: .default).weight(.black))
                    .tracking(1.5)
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.white)
                    .clipShape(Rectangle())
                    .overlay(Rectangle().stroke(Color.black, lineWidth: 2))
                    .shadow(color: .black, radius: 0, x: 3, y: 3)
                    .rotationEffect(.degrees(1))
                    .animation(ForgeMediaTokens.Motion.snappy, value: intakeHintText)

                // Demo button
                Button {
                    runVisualDemo()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 11, weight: .black))
                        Text("TRY A VISUAL DEMO")
                    }
                }
                .buttonStyle(NeoBrutalButtonStyle(.ghost))
                .help("Seeds a synthetic job to preview the activity stream")
            }
            .padding(32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Job Queue

    private var jobQueue: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Compact drop zone when jobs exist
                DropZoneView(isTargeted: $isDragTargeted) { urls in
                    model.intakeVideos(urls: urls, presetID: selectedPreset)
                }
                .frame(height: isDragTargeted ? 120 : 64)
                .padding(.horizontal, 8)
                .padding(.top, 12)
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
                                NSWorkspace.shared.open(output)
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
            .padding(.bottom, 16)
        }
        .navigationSplitViewColumnWidth(min: 420, ideal: 520)
    }

    // MARK: - Sub-views

    private var privacyBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: model.privacyMode == .privacyOn ? "lock.fill" : "lock.open")
                .font(.system(size: 9, weight: .black))
            Text(model.privacyMode == .privacyOn ? "PRIVACY ON" : "LOCAL ONLY")
                .font(.system(size: 9, weight: .black))
                .tracking(1)
        }
        .foregroundColor(.black)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            model.privacyMode == .privacyOn
                ? ForgeMediaTokens.Colors.success
                : ForgeMediaTokens.Colors.warning
        )
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.black, lineWidth: 2))
        .rotationEffect(.degrees(-2)) // sticker tilt
    }

    @ViewBuilder
    private func toolbarIconButton(systemName: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .black))
                .foregroundColor(.black)
                .frame(width: 32, height: 32)
                .background(Color.white)
                .clipShape(Rectangle())
                .overlay(Rectangle().stroke(Color.black, lineWidth: 3))
                .shadow(color: .black, radius: 0, x: 3, y: 3)
        }
        .buttonStyle(.plain)
        .help(help)
    }

    private var intakeHintText: String {
        switch hoveredIntakeAction {
        case "single":  return "Process one selected video"
        case "multi":   return "Process only selected videos"
        case "folder":  return "Process all videos in selected folder recursively"
        default:        return "Single · multi · recursive folder modes ready"
        }
    }

    // MARK: - File Pickers

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

// MARK: - Demo seeding

extension MainWindow {
    func runVisualDemo() {
        let demoURL = URL(fileURLWithPath: "/tmp/forgemedia_demo_interview_4k.mov")
        model.addJob(url: demoURL, presetID: selectedPreset)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak model] in
            model?.injectDemoActivity()
        }
    }
}
