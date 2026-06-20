import SwiftUI
import ForgeMediaDomain

/// GeexArts Premium Job Card
/// Features: Glass tiers, smooth gradient progress fills, tactile press feedback, cinematic phase transitions.
public struct JobCardView: View {
    public let job: JobRecord
    public let preset: MediaPreset?
    public let onPause: () -> Void
    public let onCancel: () -> Void
    public let onRetry: () -> Void
    public let onOpenOutput: () -> Void

    @State private var isHovered: Bool = false

    public init(job: JobRecord, preset: MediaPreset?, onPause: @escaping () -> Void, onCancel: @escaping () -> Void, onRetry: @escaping () -> Void, onOpenOutput: @escaping () -> Void) {
        self.job = job
        self.preset = preset
        self.onPause = onPause
        self.onCancel = onCancel
        self.onRetry = onRetry
        self.onOpenOutput = onOpenOutput
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header row
            HStack {
                Text(job.title)
                    .font(.system(.body, design: .default).weight(.semibold))
                    .foregroundColor(ForgeMediaTokens.Colors.fg)
                    .lineLimit(1)

                Spacer()

                phaseBadge
            }

            // Progress section
            if isProcessing {
                VStack(alignment: .leading, spacing: 6) {
                    // Smooth gradient progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(ForgeMediaTokens.Colors.borderSoft)

                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(progressGradient)
                                .frame(width: geometry.size.width * CGFloat(job.progressFraction))
                                .animation(ForgeMediaTokens.Motion.smooth, value: job.progressFraction)
                        }
                    }
                    .frame(height: 5)

                    HStack {
                        Text(job.progressLabel)
                            .font(.system(.caption, design: .default).weight(.medium))
                            .foregroundColor(ForgeMediaTokens.Colors.fgSecondary)
                        Spacer()
                        Text(confidenceLabel)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(ForgeMediaTokens.Colors.muted)
                    }
                }
            } else if isFinished {
                statusRow
            }

            // Metadata
            HStack {
                Text(preset?.name ?? "Custom Preset")
                    .font(.system(.caption2, design: .default))
                    .foregroundColor(ForgeMediaTokens.Colors.muted)
                Text("·")
                    .foregroundColor(ForgeMediaTokens.Colors.muted)
                Text("Privacy On")
                    .font(.system(.caption2, design: .default).weight(.medium))
                    .foregroundColor(ForgeMediaTokens.Colors.success)
            }
            .padding(.top, 2)

            // Actions
            if !actions.isEmpty {
                HStack(spacing: 10) {
                    Spacer()
                    ForEach(actions, id: \.title) { actionDef in
                        Button(action: actionDef.action) {
                            Text(actionDef.title)
                        }
                        .buttonStyle(.plain)
                        .font(.system(.caption, design: .default).weight(.medium))
                        .foregroundColor(actionDef.color)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(actionDef.bgColor)
                        .clipShape(RoundedRectangle(cornerRadius: ForgeMediaTokens.Radii.compact, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: ForgeMediaTokens.Radii.compact, style: .continuous)
                                .stroke(actionDef.borderColor, lineWidth: 0.5)
                        )
                        .scaleEffect(isHovered ? 1.0 : 0.98) // Tactile press prep
                        .animation(ForgeMediaTokens.Motion.snappy, value: isHovered)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(14)
        .forgeGlassCard(isElevated: isHovered)
        .scaleEffect(isHovered ? 1.005 : 1.0)
        .offset(y: isHovered ? -2 : 0)
        .animation(ForgeMediaTokens.Motion.spring, value: isHovered)
        .onHover { hovering in
            withAnimation(ForgeMediaTokens.Motion.spring) {
                isHovered = hovering
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Computed Properties

    private var isProcessing: Bool {
        [.preparing, .running, .validating].contains(job.phase)
    }

    private var isFinished: Bool {
        [.completed, .completedWithWarnings, .failed, .canceled, .recovered].contains(job.phase)
    }

    private var phaseBadge: some View {
        Text(badgeText)
            .font(.system(.caption2, design: .default).weight(.heavy))
            .foregroundColor(badgeColor)
            .padding(.horizontal, 9)
            .padding(.vertical, 3)
            .background(badgeBgColor)
            .clipShape(Capsule(style: .continuous))
            .overlay(
                Group {
                    if job.phase == .running {
                        Circle()
                            .fill(badgeColor)
                            .frame(width: 6, height: 6)
                            .padding(.trailing, 4)
                            .overlay(
                                Circle()
                                    .stroke(badgeColor.opacity(0.3), lineWidth: 4)
                                    .scaleEffect(1.5)
                                    .opacity(0.8)
                                    .animation(Animation.easeInOut(duration: 1.4).repeatForever(autoreverses: false), value: job.phase)
                            )
                    }
                },
                alignment: .leading
            )
    }

    private var badgeText: String {
        switch job.phase {
        case .completedWithWarnings: return "WARNINGS"
        default: return job.phase.rawValue.uppercased()
        }
    }

    private var badgeColor: Color {
        switch job.phase {
        case .idle, .canceled, .probing, .planning, .takingLonger: return ForgeMediaTokens.Colors.muted
        case .preparing: return ForgeMediaTokens.Colors.accent
        case .running: return ForgeMediaTokens.Colors.amber
        case .validating: return ForgeMediaTokens.Colors.teal
        case .completed: return ForgeMediaTokens.Colors.success
        case .completedWithWarnings, .paused: return ForgeMediaTokens.Colors.warning
        case .failed: return ForgeMediaTokens.Colors.rose
        case .recovered: return ForgeMediaTokens.Colors.accent
        }
    }

    private var badgeBgColor: Color {
        switch job.phase {
        case .idle, .canceled, .probing, .planning, .takingLonger: return ForgeMediaTokens.Colors.muted.opacity(0.08)
        case .preparing: return ForgeMediaTokens.Colors.accentGlow
        case .running: return ForgeMediaTokens.Colors.amberGlow
        case .validating: return ForgeMediaTokens.Colors.tealGlow
        case .completed: return ForgeMediaTokens.Colors.success.opacity(0.08)
        case .completedWithWarnings, .paused: return ForgeMediaTokens.Colors.warning.opacity(0.08)
        case .failed: return ForgeMediaTokens.Colors.roseGlow
        case .recovered: return ForgeMediaTokens.Colors.accentGlow
        }
    }

    private var progressGradient: LinearGradient {
        if job.phase == .completed || job.phase == .completedWithWarnings {
            return LinearGradient(colors: [ForgeMediaTokens.Colors.accent, ForgeMediaTokens.Colors.success], startPoint: .leading, endPoint: .trailing)
        } else if job.phase == .failed {
            return LinearGradient(colors: [ForgeMediaTokens.Colors.rose, ForgeMediaTokens.Colors.danger], startPoint: .leading, endPoint: .trailing)
        } else {
            return LinearGradient(colors: [ForgeMediaTokens.Colors.accent, ForgeMediaTokens.Colors.amber], startPoint: .leading, endPoint: .trailing)
        }
    }

    private var confidenceLabel: String {
        switch job.progressConfidence {
        case .measured: return "Measured"
        case .estimated: return "Estimated"
        case .unknown: return "Unknown"
        case .validating: return "Validating"
        }
    }

    private var statusRow: some View {
        HStack(spacing: 8) {
            Image(systemName: statusIcon)
                .font(.system(size: 13))
            Text(statusText)
                .font(.caption)
        }
        .foregroundColor(statusColor)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(statusBgColor)
        .clipShape(RoundedRectangle(cornerRadius: ForgeMediaTokens.Radii.compact, style: .continuous))
    }

    private var statusIcon: String {
        switch job.phase {
        case .completed: return "checkmark.circle.fill"
        case .completedWithWarnings: return "exclamationmark.triangle.fill"
        case .failed: return "xmark.octagon.fill"
        case .canceled: return "xmark.circle.fill"
        case .recovered: return "arrow.counterclockwise.circle.fill"
        default: return "info.circle.fill"
        }
    }

    private var statusText: String {
        switch job.phase {
        case .completed: return "Output saved · Checksum verified"
        case .completedWithWarnings: return "Complete · Minor warnings (output usable)"
        case .failed: return "Could not read video stream. Try FFmpeg engine."
        case .canceled: return "Canceled by user"
        case .recovered: return "Recovered from checkpoint"
        default: return "Unknown state"
        }
    }

    private var statusColor: Color {
        switch job.phase {
        case .completed: return ForgeMediaTokens.Colors.success
        case .completedWithWarnings: return ForgeMediaTokens.Colors.warning
        case .failed, .canceled: return ForgeMediaTokens.Colors.rose
        case .recovered: return ForgeMediaTokens.Colors.accent
        case .idle, .preparing, .probing, .planning, .running, .validating, .paused, .takingLonger: return ForgeMediaTokens.Colors.muted
        }
    }

    private var statusBgColor: Color {
        switch job.phase {
        case .completed: return ForgeMediaTokens.Colors.success.opacity(0.08)
        case .completedWithWarnings: return ForgeMediaTokens.Colors.warning.opacity(0.08)
        case .failed, .canceled: return ForgeMediaTokens.Colors.roseGlow
        case .recovered: return ForgeMediaTokens.Colors.accentGlow
        case .idle, .preparing, .probing, .planning, .running, .validating, .paused, .takingLonger: return ForgeMediaTokens.Colors.muted.opacity(0.05)
        }
    }

    private struct ActionButtonDef {
        let title: String
        let action: () -> Void
        let color: Color
        let bgColor: Color
        let borderColor: Color
    }

    private var actions: [ActionButtonDef] {
        switch job.phase {
        case .preparing, .running, .validating:
            return [
                ActionButtonDef(title: "Pause", action: onPause, color: ForgeMediaTokens.Colors.fg, bgColor: Color.black.opacity(0.05), borderColor: ForgeMediaTokens.Colors.border),
                ActionButtonDef(title: "Cancel", action: onCancel, color: ForgeMediaTokens.Colors.rose, bgColor: Color.clear, borderColor: Color.clear)
            ]
        case .completed, .completedWithWarnings:
            return [
                ActionButtonDef(title: "Open Output", action: onOpenOutput, color: .white, bgColor: ForgeMediaTokens.Colors.accent, borderColor: Color.clear),
                ActionButtonDef(title: "Share", action: {}, color: ForgeMediaTokens.Colors.fgSecondary, bgColor: Color.clear, borderColor: Color.clear)
            ]
        case .failed:
            return [
                ActionButtonDef(title: "Retry", action: onRetry, color: .white, bgColor: ForgeMediaTokens.Colors.accent, borderColor: Color.clear),
                ActionButtonDef(title: "Diagnostics", action: {}, color: ForgeMediaTokens.Colors.muted, bgColor: Color.clear, borderColor: Color.clear)
            ]
        case .canceled:
            return [
                ActionButtonDef(title: "Resume from checkpoint", action: onRetry, color: ForgeMediaTokens.Colors.fg, bgColor: Color.black.opacity(0.05), borderColor: ForgeMediaTokens.Colors.border)
            ]
        case .idle, .probing, .planning, .paused, .takingLonger, .recovered:
            return []
        }
    }
}

// MARK: - Preview

#if DEBUG
struct JobCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            JobCardView(
                job: JobRecord(title: "interview_4k_raw.mov", sourceURL: URL(fileURLWithPath: "/tmp/test.mov"), presetID: "convert_h264", phase: .running, progressFraction: 0.57, progressConfidence: .measured, progressLabel: "Processing segment 3 of 6…"),
                preset: MediaPreset.builtIn[1],
                onPause: {}, onCancel: {}, onRetry: {}, onOpenOutput: {}
            )
            JobCardView(
                job: JobRecord(title: "podcast_ep42.wav", sourceURL: URL(fileURLWithPath: "/tmp/test.wav"), presetID: "transcribe", phase: .completed, progressFraction: 1.0, progressConfidence: .measured, progressLabel: "Complete"),
                preset: MediaPreset.builtIn[0],
                onPause: {}, onCancel: {}, onRetry: {}, onOpenOutput: {}
            )
        }
        .frame(width: 420)
        .padding()
        .background(ForgeMediaTokens.Colors.bg)
    }
}
#endif