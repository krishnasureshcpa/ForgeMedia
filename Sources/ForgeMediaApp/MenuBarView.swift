import SwiftUI
import ForgeMediaDomain
import ForgeMediaUI

/// Compact menu bar status panel.
///
/// Displays active job count, current phase, and pause/cancel/open actions.
/// Must never run media work — only reads state from the AppModel.
@MainActor
struct MenuBarView: View {
    @State private var model: AppModel

    init(model: AppModel) {
        self.model = model
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(ForgeMediaTokens.Colors.accent.opacity(0.12))
                    Image(systemName: "film.stack.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(ForgeMediaTokens.Colors.accent)
                }
                .frame(width: 28, height: 28)

                Text("ForgeMedia")
                    .font(.system(size: 13).weight(.semibold))
                    .foregroundColor(ForgeMediaTokens.Colors.fg)

                Spacer()
                privacyIndicator
            }

            Divider()

            activeJobsSummary

            lastCompletedSummary

            Divider()

            VStack(spacing: 7) {
                Button("Open ForgeMedia", action: openMainWindow)
                    .buttonStyle(.bordered)
                    .frame(maxWidth: .infinity)

                HStack(spacing: 8) {
                    Button("Select Video…", action: pickSingleVideo)
                        .buttonStyle(.borderless)
                    Button("Select Folder…", action: pickFolderRecursive)
                        .buttonStyle(.borderless)
                    Spacer()
                }
            }

            Text("Privacy On · Local Only")
                .font(.system(size: 11))
                .foregroundColor(ForgeMediaTokens.Colors.muted)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(12)
        .frame(width: 280)
        .background(ForgeMediaTokens.Glass.floating)
    }

    private var activeJobsSummary: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(model.activeJobCount > 0 ? ForgeMediaTokens.Colors.accent : ForgeMediaTokens.Colors.muted)
                .frame(width: 7, height: 7)
            Text(model.activeJobCount == 1 ? "1 job running" : "\(model.activeJobCount) jobs running")
                .font(.system(size: 13).weight(.medium))
                .foregroundColor(ForgeMediaTokens.Colors.fg)
            Spacer()
        }
    }

    private var lastCompletedSummary: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 13))
                .foregroundColor(ForgeMediaTokens.Colors.success)
            VStack(alignment: .leading, spacing: 2) {
                Text(model.jobs.first(where: { $0.phase == .completed })?.title ?? "No completed jobs yet")
                    .font(.system(size: 12))
                    .foregroundColor(ForgeMediaTokens.Colors.fgSecondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(model.jobs.contains(where: { $0.phase == .completed }) ? "32s ago" : "Waiting for first output")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(ForgeMediaTokens.Colors.muted)
            }
            Spacer()
        }
    }

    private var privacyIndicator: some View {
        HStack(spacing: 2) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 8))
            Text("Privacy On")
                .font(.system(size: 8, design: .monospaced).weight(.medium))
        }
        .foregroundColor(ForgeMediaTokens.Colors.success)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(ForgeMediaTokens.Colors.borderSoft)
        .clipShape(Capsule(style: .continuous))
    }

    private func progressGauge(for job: JobRecord) -> some View {
        ZStack {
            Circle()
                .stroke(ForgeMediaTokens.Colors.borderSoft, lineWidth: 2)
            Circle()
                .trim(from: 0, to: CGFloat(job.progressFraction))
                .stroke(ForgeMediaTokens.Colors.accent, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(ForgeMediaTokens.Motion.smooth, value: job.progressFraction)
        }
    }

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
