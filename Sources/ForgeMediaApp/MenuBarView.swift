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
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("ForgeMedia")
                    .font(.system(.headline).weight(.semibold))
                Spacer()
                privacyIndicator
            }

            Divider()

            if model.activeJobCount == 0 {
                Text("No active jobs")
                    .font(.system(.callout))
                    .foregroundColor(ForgeMediaTokens.Colors.muted)
                    .padding(.vertical, 4)
            } else {
                // Show first active job
                ForEach(model.jobs.prefix(3).filter { $0.phase != .idle && $0.phase != .completed && $0.phase != .canceled && $0.phase != .failed }) { job in
                    HStack(spacing: 8) {
                        progressGauge(for: job)
                            .frame(width: 20, height: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(job.title)
                                .font(.system(.callout))
                                .lineLimit(1)
                                .foregroundColor(ForgeMediaTokens.Colors.fg)
                            Text(job.progressLabel)
                                .font(.system(.caption2))
                                .foregroundColor(ForgeMediaTokens.Colors.muted)
                                .lineLimit(1)
                        }

                        Spacer()

                        if job.phase == .running || job.phase == .preparing {
                            Button {
                                Task { await model.cancelJob(job) }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(ForgeMediaTokens.Colors.danger)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Divider()

            // Bottom actions
            HStack {
                Button("Open ForgeMedia") {
                    model.showJobsPanel = true
                    NSApp.activate(ignoringOtherApps: true)
                    if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" }) {
                        window.makeKeyAndOrderFront(nil)
                    } else if let window = NSApp.windows.first(where: { $0.canBecomeMain }) {
                        window.makeKeyAndOrderFront(nil)
                    }
                }
                .buttonStyle(.borderless)
                .font(.system(.callout))

                Spacer()

                Text("\(model.activeJobCount) active")
                    .font(.system(.caption2))
                    .foregroundColor(ForgeMediaTokens.Colors.muted)
            }
        }
        .padding()
        .frame(width: 280)
    }

    private var privacyIndicator: some View {
        HStack(spacing: 2) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 8))
            Text("Local")
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
}