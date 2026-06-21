import SwiftUI
import ForgeMediaDomain

/// ForgeMedia job card — neo-brutalist styled.
///
/// Visual language: white fill · 4px black border · hard offset shadow ·
/// physical lift on hover (offset -4pt, shadow 10×10) · solid-fill phase badges
/// with black borders · rectangular progress bar · mechanical action buttons.
public struct JobCardView: View {
    public let job: JobRecord
    public let preset: MediaPreset?
    public let onPause: () -> Void
    public let onCancel: () -> Void
    public let onRetry: () -> Void
    public let onOpenOutput: () -> Void

    @State private var isHovered: Bool = false

    public init(
        job: JobRecord, preset: MediaPreset?,
        onPause: @escaping () -> Void,
        onCancel: @escaping () -> Void,
        onRetry: @escaping () -> Void,
        onOpenOutput: @escaping () -> Void
    ) {
        self.job = job; self.preset = preset
        self.onPause = onPause; self.onCancel = onCancel
        self.onRetry = onRetry; self.onOpenOutput = onOpenOutput
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // ── Header row ────────────────────────────────────────────────────
            HStack(alignment: .center, spacing: 10) {
                // Phase indicator strip (vertical sticker on left edge)
                Rectangle()
                    .fill(phaseAccentColor)
                    .frame(width: 4, height: 20)

                Text(job.title)
                    .font(.system(.body, design: .default).weight(.black))
                    .foregroundColor(.black)
                    .lineLimit(1)

                Spacer()

                phaseBadge
            }

            // ── Progress ──────────────────────────────────────────────────────
            if isProcessing {
                VStack(alignment: .leading, spacing: 6) {
                    neoProgressBar
                    HStack {
                        Text(job.progressLabel)
                            .font(.system(.caption, design: .default).weight(.bold))
                            .foregroundColor(.black.opacity(0.70))
                        Spacer()
                        Text(confidenceLabel.uppercased())
                            .font(.system(.caption2, design: .monospaced).weight(.bold))
                            .tracking(1)
                            .foregroundColor(.black.opacity(0.45))
                    }
                }
            } else if isFinished {
                statusStrip
            }

            // ── Metadata ──────────────────────────────────────────────────────
            HStack(spacing: 6) {
                Text((preset?.name ?? "Custom Preset").uppercased())
                    .font(.system(.caption2, design: .default).weight(.bold))
                    .tracking(1)
                    .foregroundColor(.black.opacity(0.50))

                Rectangle()
                    .fill(Color.black.opacity(0.25))
                    .frame(width: 1, height: 10)

                HStack(spacing: 3) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9, weight: .black))
                    Text("PRIVACY ON")
                        .font(.system(.caption2).weight(.black))
                        .tracking(1)
                }
                .foregroundColor(.black)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(ForgeMediaTokens.Colors.success)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.black, lineWidth: 1.5))
            }

            // ── Actions ───────────────────────────────────────────────────────
            if !actions.isEmpty {
                HStack(spacing: 8) {
                    Spacer()
                    ForEach(actions, id: \.title) { def in
                        Button(def.title.uppercased(), action: def.action)
                            .buttonStyle(NeoBrutalButtonStyle(def.variant))
                    }
                }
            }
        }
        .padding(14)
        // Neo card: white fill · 4px border · shadow that grows on hover
        .background(Color.white)
        .clipShape(Rectangle())
        .overlay(Rectangle().stroke(Color.black, lineWidth: isHovered ? 4 : 4))
        .shadow(color: .black, radius: 0,
                x: isHovered ? 10 : 6, y: isHovered ? 10 : 6)
        // Physical lift on hover
        .offset(y: isHovered ? -4 : 0)
        .animation(ForgeMediaTokens.Motion.spring, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Sub-views

    private var phaseBadge: some View {
        Text(badgeLabel)
            .font(.system(size: 10, weight: .black))
            .tracking(1.5)
            .foregroundColor(.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(phaseBadgeFill)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.black, lineWidth: 2))
    }

    private var neoProgressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track — cream with border
                Rectangle()
                    .fill(ForgeMediaTokens.Colors.canvas)
                    .overlay(Rectangle().stroke(Color.black, lineWidth: 2))

                // Fill — solid accent color, no gradient
                Rectangle()
                    .fill(progressFillColor)
                    .overlay(
                        Rectangle()
                            .stroke(Color.black, lineWidth: 1)
                            .opacity(0.5)
                    )
                    .frame(width: geo.size.width * CGFloat(job.progressFraction))
                    .animation(ForgeMediaTokens.Motion.smooth, value: job.progressFraction)
            }
        }
        .frame(height: 10)
        .clipShape(Rectangle())
    }

    private var statusStrip: some View {
        HStack(spacing: 8) {
            Image(systemName: statusIcon)
                .font(.system(size: 13, weight: .bold))
            Text(statusText)
                .font(.system(.caption).weight(.bold))
            Spacer()
        }
        .foregroundColor(.black)
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(statusStripFill)
        .clipShape(Rectangle())
        .overlay(Rectangle().stroke(Color.black, lineWidth: 2))
    }

    // MARK: - Computed Properties

    private var isProcessing: Bool {
        [.preparing, .running, .validating, .takingLonger,
         .separating, .transcribing, .stabilizing].contains(job.phase)
    }

    private var isFinished: Bool {
        [.completed, .completedWithWarnings, .failed, .canceled, .recovered].contains(job.phase)
    }

    private var badgeLabel: String {
        switch job.phase {
        case .completedWithWarnings: return "WARNINGS"
        default: return job.phase.rawValue.uppercased()
        }
    }

    /// Solid fill for the phase badge chip.
    private var phaseBadgeFill: Color {
        switch job.phase {
        case .idle, .probing, .planning, .canceled:
            return ForgeMediaTokens.Colors.canvas
        case .preparing, .running, .separating, .transcribing, .stabilizing:
            return ForgeMediaTokens.Colors.accent
        case .takingLonger:
            return ForgeMediaTokens.Colors.warning
        case .validating:
            return ForgeMediaTokens.Colors.neomuted
        case .completed:
            return ForgeMediaTokens.Colors.success
        case .completedWithWarnings, .paused:
            return ForgeMediaTokens.Colors.secondary
        case .failed:
            return ForgeMediaTokens.Colors.danger
        case .recovered:
            return ForgeMediaTokens.Colors.teal
        }
    }

    /// Color for the left accent strip on the card header.
    private var phaseAccentColor: Color { phaseBadgeFill }

    // Legacy-named properties kept for existing switch exhaustiveness
    private var badgeColor: Color { phaseBadgeFill }
    private var badgeBgColor: Color { phaseBadgeFill }

    private var progressFillColor: Color {
        switch job.phase {
        case .failed:    return ForgeMediaTokens.Colors.danger
        case .takingLonger: return ForgeMediaTokens.Colors.warning
        case .completed, .completedWithWarnings: return ForgeMediaTokens.Colors.success
        default: return ForgeMediaTokens.Colors.accent
        }
    }

    private var progressGradient: LinearGradient {
        // Kept for any legacy reference — maps to solid fill wrapped in gradient
        LinearGradient(colors: [progressFillColor, progressFillColor],
                       startPoint: .leading, endPoint: .trailing)
    }

    private var confidenceLabel: String {
        switch job.progressConfidence {
        case .measured:   return "Measured"
        case .estimated:  return "Estimated"
        case .unknown:    return "Unknown"
        case .validating: return "Validating"
        }
    }

    private var statusIcon: String {
        switch job.phase {
        case .completed:             return "checkmark.square.fill"
        case .completedWithWarnings: return "exclamationmark.triangle.fill"
        case .failed:                return "xmark.square.fill"
        case .canceled:              return "xmark.circle.fill"
        case .recovered:             return "arrow.counterclockwise.circle.fill"
        default:                     return "info.circle.fill"
        }
    }

    private var statusText: String {
        switch job.phase {
        case .completed:             return "Output saved · Checksum verified"
        case .completedWithWarnings: return "Complete · Minor warnings (output usable)"
        case .failed:                return "Could not read video stream. Try FFmpeg engine."
        case .canceled:              return "Canceled by user"
        case .recovered:             return "Recovered from checkpoint"
        default:                     return "Unknown state"
        }
    }

    private var statusColor: Color {
        switch job.phase {
        case .completed:   return ForgeMediaTokens.Colors.success
        case .completedWithWarnings: return ForgeMediaTokens.Colors.warning
        case .failed, .canceled: return ForgeMediaTokens.Colors.danger
        case .recovered:   return ForgeMediaTokens.Colors.teal
        case .idle, .preparing, .probing, .planning, .running,
             .separating, .transcribing, .stabilizing,
             .validating, .paused, .takingLonger:
            return .black.opacity(0.55)
        }
    }

    private var statusBgColor: Color { statusStripFill }

    private var statusStripFill: Color {
        switch job.phase {
        case .completed:             return ForgeMediaTokens.Colors.success.opacity(0.15)
        case .completedWithWarnings: return ForgeMediaTokens.Colors.secondary.opacity(0.40)
        case .failed, .canceled:     return ForgeMediaTokens.Colors.danger.opacity(0.12)
        case .recovered:             return ForgeMediaTokens.Colors.teal.opacity(0.15)
        default:                     return ForgeMediaTokens.Colors.canvas
        }
    }

    // MARK: - Action Definitions

    private struct ActionDef {
        let title: String
        let action: () -> Void
        let variant: NeoBrutalButtonStyle.Variant
    }

    private var actions: [ActionDef] {
        switch job.phase {
        case .preparing, .running, .validating, .separating, .transcribing, .stabilizing:
            return [
                ActionDef(title: "Pause",  action: onPause,  variant: .outline),
                ActionDef(title: "Cancel", action: onCancel, variant: .primary),
            ]
        case .completed, .completedWithWarnings:
            return [
                ActionDef(title: "Open Output", action: onOpenOutput, variant: .secondary),
                ActionDef(title: "Share",        action: {},           variant: .outline),
            ]
        case .failed:
            return [
                ActionDef(title: "Retry",       action: onRetry, variant: .primary),
                ActionDef(title: "Diagnostics", action: {},      variant: .outline),
            ]
        case .canceled:
            return [
                ActionDef(title: "Resume from checkpoint", action: onRetry, variant: .secondary),
            ]
        default:
            return []
        }
    }
}

// MARK: - Preview

#if DEBUG
struct JobCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            JobCardView(
                job: JobRecord(
                    title: "interview_4k_raw.mov",
                    sourceURL: URL(fileURLWithPath: "/tmp/test.mov"),
                    presetID: "restore_4k",
                    phase: .running,
                    progressFraction: 0.57,
                    progressConfidence: .measured,
                    progressLabel: "Stabilizing · segment 3 of 6…"
                ),
                preset: MediaPreset.builtIn.first(where: { $0.id == "restore_4k" }),
                onPause: {}, onCancel: {}, onRetry: {}, onOpenOutput: {}
            )
            JobCardView(
                job: JobRecord(
                    title: "podcast_ep42.wav",
                    sourceURL: URL(fileURLWithPath: "/tmp/test.wav"),
                    presetID: "transcribe",
                    phase: .completed,
                    progressFraction: 1.0,
                    progressConfidence: .measured,
                    progressLabel: "Complete"
                ),
                preset: MediaPreset.builtIn.first(where: { $0.id == "transcribe" }),
                onPause: {}, onCancel: {}, onRetry: {}, onOpenOutput: {}
            )
        }
        .frame(width: 460)
        .padding(32)
        .background(ForgeMediaTokens.Colors.canvas)
    }
}
#endif
