import SwiftUI
import ForgeMediaDomain
import ForgeMediaUI

/// Compact menu-bar status panel — neo-brutalist styled.
///
/// Visual language: white fill · 4px black border · hard shadow ·
/// bordered logo sticker · bold uppercase labels · neo push-down buttons.
/// Never runs media work — reads state from AppModel only.
@MainActor
struct MenuBarView: View {
    @State private var model: AppModel

    init(model: AppModel) {
        self.model = model
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            panelHeader
            heavyRule
            activeJobsSummary
            lastCompletedSummary
            heavyRule
            actionButtons

            // Footer privacy tag
            HStack {
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 8, weight: .black))
                    Text("PRIVACY ON · LOCAL ONLY")
                        .font(.system(size: 8, weight: .black))
                        .tracking(1.5)
                }
                .foregroundColor(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(ForgeMediaTokens.Colors.success)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.black, lineWidth: 1.5))
                Spacer()
            }
        }
        .padding(14)
        .frame(width: 288)
        .background(Color.white)
        .clipShape(Rectangle())
        .overlay(Rectangle().stroke(Color.black, lineWidth: 4))
        .shadow(color: .black, radius: 0, x: 6, y: 6)
    }

    // MARK: - Sub-views

    private var panelHeader: some View {
        HStack(spacing: 8) {
            // Logo sticker — yellow bordered box
            HStack(spacing: 5) {
                Image(systemName: "film.stack.fill")
                    .font(.system(size: 11, weight: .black))
                Text("FM")
                    .font(.system(size: 13, weight: .black))
                    .tracking(1)
            }
            .foregroundColor(.black)
            .frame(width: 42, height: 34)
            .background(ForgeMediaTokens.Colors.secondary)
            .clipShape(Rectangle())
            .overlay(Rectangle().stroke(Color.black, lineWidth: 3))
            .shadow(color: .black, radius: 0, x: 3, y: 3)
            .rotationEffect(.degrees(-1))

            VStack(alignment: .leading, spacing: 1) {
                Text("FORGEMEDIA")
                    .font(.system(size: 12, weight: .black))
                    .tracking(2)
                    .foregroundColor(.black)
                Text("Media Command Center")
                    .font(.system(size: 10).weight(.bold))
                    .foregroundColor(.black.opacity(0.50))
            }

            Spacer()
            privacyIndicator
        }
    }

    private var activeJobsSummary: some View {
        HStack(spacing: 8) {
            // Status dot
            Circle()
                .fill(model.activeJobCount > 0
                      ? ForgeMediaTokens.Colors.accent
                      : Color.black.opacity(0.25))
                .frame(width: 8, height: 8)
                .overlay(
                    Circle().stroke(Color.black, lineWidth: 1.5)
                )

            Text(
                model.activeJobCount == 0
                    ? "NO JOBS RUNNING"
                    : model.activeJobCount == 1
                        ? "1 JOB RUNNING"
                        : "\(model.activeJobCount) JOBS RUNNING"
            )
            .font(.system(size: 11, weight: .black))
            .tracking(1.5)
            .foregroundColor(.black)

            Spacer()
        }
    }

    private var lastCompletedSummary: some View {
        HStack(alignment: .top, spacing: 8) {
            // Checkmark in a bordered square
            ZStack {
                Rectangle()
                    .fill(ForgeMediaTokens.Colors.success.opacity(0.15))
                    .frame(width: 22, height: 22)
                    .overlay(Rectangle().stroke(ForgeMediaTokens.Colors.success, lineWidth: 2))
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(ForgeMediaTokens.Colors.success)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(model.jobs.first(where: { $0.phase == .completed })?.title ?? "—")
                    .font(.system(size: 11).weight(.bold))
                    .foregroundColor(.black.opacity(0.75))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(model.jobs.contains(where: { $0.phase == .completed })
                     ? "LAST COMPLETED"
                     : "WAITING FOR OUTPUT")
                .font(.system(size: 9, design: .monospaced).weight(.bold))
                .tracking(1)
                .foregroundColor(.black.opacity(0.40))
            }
            Spacer()
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 9) {
            Button("OPEN FORGEMEDIA", action: openMainWindow)
                .buttonStyle(NeoBrutalButtonStyle(.secondary))
                .frame(maxWidth: .infinity)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Button("SELECT VIDEO…", action: pickSingleVideo)
                    .buttonStyle(NeoBrutalButtonStyle(.outline))
                Button("SELECT FOLDER…", action: pickFolderRecursive)
                    .buttonStyle(NeoBrutalButtonStyle(.outline))
                Spacer()
            }
        }
    }

    private var privacyIndicator: some View {
        HStack(spacing: 3) {
            Image(systemName: "lock.fill")
                .font(.system(size: 8, weight: .black))
            Text("ON")
                .font(.system(size: 8, weight: .black))
        }
        .foregroundColor(.black)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(ForgeMediaTokens.Colors.success)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.black, lineWidth: 1.5))
    }

    /// A 3px solid black rule — neo-brutalist divider.
    private var heavyRule: some View {
        Rectangle()
            .fill(Color.black)
            .frame(height: 3)
    }

    // MARK: - Progress gauge (compact circular indicator)

    private func progressGauge(for job: JobRecord) -> some View {
        ZStack {
            Circle()
                .stroke(Color.black.opacity(0.15), lineWidth: 2)
            Circle()
                .trim(from: 0, to: CGFloat(job.progressFraction))
                .stroke(ForgeMediaTokens.Colors.accent,
                        style: StrokeStyle(lineWidth: 2, lineCap: .butt))
                .rotationEffect(.degrees(-90))
                .animation(ForgeMediaTokens.Motion.smooth, value: job.progressFraction)
        }
    }

    // MARK: - Actions

    private func openMainWindow() {
        model.showJobsPanel = true
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" }) {
            window.makeKeyAndOrderFront(nil)
        } else if let window = NSApp.windows.first(where: { $0.canBecomeMain }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            NotificationCenter.default.post(name: .forgeOpenMainWindow, object: nil)
        }
    }

    private func pickSingleVideo() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.movie]
        if panel.runModal() == .OK, let url = panel.url {
            model.intakeVideo(url: url)
            openMainWindow()
        }
    }

    private func pickFolderRecursive() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            model.intakeFolder(folderURL: url, recursive: true)
            openMainWindow()
        }
    }
}
