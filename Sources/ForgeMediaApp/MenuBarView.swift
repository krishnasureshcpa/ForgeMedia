import SwiftUI
import ForgeMediaDomain
import ForgeMediaUI

/// Compact menu-bar status panel — retro macOS popup window.
///
/// 288px wide window card: cream fill · 1px taupe border · warm shadow.
/// Title bar (menu-bar surface) · stats body · action buttons · privacy footer.
/// Never runs media work — reads state from AppModel only.
@MainActor
struct MenuBarView: View {
    @State private var model: AppModel

    init(model: AppModel) {
        self.model = model
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            panelTitleBar
            Divider().overlay(ForgeMediaTokens.Colors.borderDefault)
            statsBody
            Divider().overlay(ForgeMediaTokens.Colors.borderDefault)
            actionButtons
            Divider().overlay(ForgeMediaTokens.Colors.borderDefault)
            privacyFooter
        }
        .frame(width: 288)
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

    private var panelTitleBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "film.stack.fill")
                    .font(.system(size: 10, weight: .medium))
                Text("FM")
                    .font(.system(size: 12, weight: .semibold, design: .serif))
            }
            .foregroundColor(ForgeMediaTokens.Colors.heading)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(ForgeMediaTokens.Colors.brandSofter)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(ForgeMediaTokens.Colors.borderSubtle, lineWidth: 1)
            )

            VStack(alignment: .leading, spacing: 0) {
                Text("FORGEMEDIA")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .tracking(1)
                    .foregroundColor(ForgeMediaTokens.Colors.heading)
                Text("Media Command Center")
                    .font(.system(size: 9))
                    .foregroundColor(ForgeMediaTokens.Colors.bodySubtle)
            }

            Spacer()

            // Privacy indicator
            HStack(spacing: 3) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 8))
                Text("LOCAL")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
            }
            .foregroundColor(ForgeMediaTokens.Colors.success)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(ForgeMediaTokens.Colors.successSoft)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(ForgeMediaTokens.Colors.success.opacity(0.4), lineWidth: 1)
            )
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
        .background(ForgeMediaTokens.Colors.menuBar)
    }

    // MARK: - Stats Body

    private var statsBody: some View {
        VStack(spacing: 10) {
            // Running jobs
            HStack(spacing: 8) {
                Circle()
                    .fill(model.activeJobCount > 0
                          ? ForgeMediaTokens.Colors.brand
                          : ForgeMediaTokens.Colors.borderSubtle)
                    .frame(width: 7, height: 7)

                Text(model.activeJobCount == 0
                     ? "No jobs running"
                     : model.activeJobCount == 1
                         ? "1 job running"
                         : "\(model.activeJobCount) jobs running")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(ForgeMediaTokens.Colors.heading)

                Spacer()
            }

            // Last completed
            HStack(alignment: .top, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(ForgeMediaTokens.Colors.successSoft)
                        .frame(width: 22, height: 22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(ForgeMediaTokens.Colors.success.opacity(0.4), lineWidth: 1)
                        )
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(ForgeMediaTokens.Colors.success)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(model.jobs.first(where: { $0.phase == .completed })?.title ?? "—")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(ForgeMediaTokens.Colors.body)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Text(model.jobs.contains(where: { $0.phase == .completed })
                         ? "LAST COMPLETED"
                         : "NO OUTPUT YET")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .tracking(0.5)
                        .foregroundColor(ForgeMediaTokens.Colors.bodySubtle)
                }
                Spacer()
            }
        }
        .padding(12)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 8) {
            Button("Open ForgeMedia", action: openMainWindow)
                .buttonStyle(ForgeButtonStyle(.primary))
                .frame(maxWidth: .infinity)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Button("Select Video…", action: pickSingleVideo)
                    .buttonStyle(ForgeButtonStyle(.outline))
                Button("Select Folder…", action: pickFolderRecursive)
                    .buttonStyle(ForgeButtonStyle(.outline))
                Spacer()
            }
        }
        .padding(12)
    }

    // MARK: - Privacy Footer

    private var privacyFooter: some View {
        HStack {
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 8))
                Text("Files stay on your Mac · no cloud uploads")
                    .font(.system(size: 9, design: .monospaced))
            }
            .foregroundColor(ForgeMediaTokens.Colors.brand)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(ForgeMediaTokens.Colors.brandSofter)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(ForgeMediaTokens.Colors.borderSubtle, lineWidth: 1)
            )
            Spacer()
        }
        .padding(.vertical, 10)
        .background(ForgeMediaTokens.Colors.secondarySurface)
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
        panel.canChooseFiles = true; panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false; panel.allowedContentTypes = [.movie]
        if panel.runModal() == .OK, let url = panel.url {
            model.intakeVideo(url: url)
            openMainWindow()
        }
    }

    private func pickFolderRecursive() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false; panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            model.intakeFolder(folderURL: url, recursive: true)
            openMainWindow()
        }
    }
}
