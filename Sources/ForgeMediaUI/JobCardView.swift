import SwiftUI
import ForgeMediaDomain

/// Job card — retro macOS "window" metaphor.
///
/// Structure:
///   ┌─ 32px title bar (menu-bar surface, 1px bottom border) ──────────┐
///   │  [● ●]  filename.mov          [⏸] [✕]                           │
///   ├─────────────────────────────────────────────────────────────────┤
///   │ [RUNNING] · Convert H.264          57%  ████████░░░░            │
///   │  Encoding segment 3 of 6 · elapsed 00:04:32                     │
///   │▐═════════════════════════════════════░░░░░░░░░░░░░░░░░░░░░░░░░░│  4px
///   └─────────────────────────────────────────────────────────────────┘
public struct JobCardView: View {
    public let job: JobRecord
    public let preset: MediaPreset?
    public let onPause: () -> Void
    public let onCancel: () -> Void
    public let onRetry: () -> Void
    public let onOpenOutput: () -> Void

    @State private var isHovered = false

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
        VStack(spacing: 0) {
            titleBar
            Divider()
                .overlay(ForgeMediaTokens.Colors.borderDefault)
            cardBody
            if isProcessing {
                progressBar
            }
        }
        .background(ForgeMediaTokens.Colors.canvas)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(
                    isHovered
                    ? ForgeMediaTokens.Colors.borderStrong
                    : ForgeMediaTokens.Colors.borderDefault,
                    lineWidth: 1
                )
        )
        .shadow(
            color: ForgeMediaTokens.Shadow.windowLo.color,
            radius: isHovered ? 12 : ForgeMediaTokens.Shadow.windowLo.radius,
            x: 0, y: isHovered ? 6 : ForgeMediaTokens.Shadow.windowLo.y
        )
        .offset(y: isHovered ? -1 : 0)
        .animation(ForgeMediaTokens.Motion.spring, value: isHovered)
        .onHover { isHovered = $0 }
        .padding(.horizontal, 10)
    }

    // MARK: - Title Bar

    private var titleBar: some View {
        HStack(spacing: 8) {
            // Decorative window dots
            HStack(spacing: 4) {
                Circle().fill(Color(hex: "#FF5F57")).frame(width: 8, height: 8)
                Circle().fill(Color(hex: "#FEBC2E")).frame(width: 8, height: 8)
            }

            // Phase indicator dot
            Circle()
                .fill(phaseAccent)
                .frame(width: 7, height: 7)
                .overlay(Circle().stroke(ForgeMediaTokens.Colors.borderDefault, lineWidth: 0.5))

            // Filename — monospaced, truncate middle
            Text(job.title)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(ForgeMediaTokens.Colors.heading)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            // Action icon buttons
            HStack(spacing: 4) {
                ForEach(iconActions, id: \.icon) { btn in
                    Button(action: btn.action) {
                        Image(systemName: btn.icon)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(btn.isDestructive
                                ? ForgeMediaTokens.Colors.danger
                                : ForgeMediaTokens.Colors.bodySubtle)
                            .frame(width: 22, height: 22)
                            .background(ForgeMediaTokens.Colors.menuBar)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                            .overlay(
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(ForgeMediaTokens.Colors.borderDefault, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .help(btn.tooltip)
                }
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 32)
        .background(ForgeMediaTokens.Colors.menuBar)
    }

    // MARK: - Card Body

    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                phaseBadge
                Text("·")
                    .font(.system(size: 10))
                    .foregroundColor(ForgeMediaTokens.Colors.borderDefault)
                Text((preset?.name ?? "Custom").uppercased())
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(ForgeMediaTokens.Colors.bodySubtle)
                Spacer()
                if isProcessing {
                    Text("\(Int(job.progressFraction * 100))%")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(ForgeMediaTokens.Colors.heading)
                }
            }

            if isProcessing && !job.progressLabel.isEmpty {
                Text(job.progressLabel)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(ForgeMediaTokens.Colors.bodySubtle)
                    .lineLimit(1)
            }

            if isFinished {
                HStack(spacing: 6) {
                    Image(systemName: statusIcon)
                        .font(.system(size: 10))
                        .foregroundColor(statusColor)
                    Text(statusText)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(ForgeMediaTokens.Colors.bodySubtle)
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusBg)
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(ForgeMediaTokens.Colors.borderSubtle, lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
    }

    // MARK: - Progress Bar (4px, flush at bottom)

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(ForgeMediaTokens.Colors.inputBg)
                Rectangle()
                    .fill(progressFill)
                    .frame(width: geo.size.width * CGFloat(max(0, min(1, job.progressFraction))))
                    .animation(ForgeMediaTokens.Motion.smooth, value: job.progressFraction)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Phase Badge

    private var phaseBadge: some View {
        Text(badgeLabel)
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .tracking(0.5)
            .foregroundColor(phaseTextColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(phaseBg)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(phaseBorderColor, lineWidth: 1)
            )
    }

    // MARK: - Computed

    private var isProcessing: Bool {
        [.preparing, .running, .validating, .takingLonger,
         .probing, .planning, .separating, .transcribing, .stabilizing].contains(job.phase)
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

    private var phaseAccent: Color {
        switch job.phase {
        case .idle, .canceled:                                                return ForgeMediaTokens.Colors.borderSubtle
        case .probing, .planning, .preparing, .validating:                    return ForgeMediaTokens.Colors.brandMedium
        case .running, .separating, .transcribing, .stabilizing:             return ForgeMediaTokens.Colors.brand
        case .takingLonger:                                                   return ForgeMediaTokens.Colors.warning
        case .completed:                                                      return ForgeMediaTokens.Colors.success
        case .completedWithWarnings, .paused:                                 return ForgeMediaTokens.Colors.warning
        case .failed:                                                         return ForgeMediaTokens.Colors.danger
        case .recovered:                                                      return ForgeMediaTokens.Colors.teal
        }
    }

    private var phaseBg: Color {
        switch job.phase {
        case .running, .separating, .transcribing, .stabilizing, .preparing: return ForgeMediaTokens.Colors.brandSofter
        case .takingLonger, .completedWithWarnings, .paused:                  return ForgeMediaTokens.Colors.warningSoft
        case .completed:                                                      return ForgeMediaTokens.Colors.successSoft
        case .failed, .canceled:                                              return ForgeMediaTokens.Colors.dangerSoft
        default:                                                              return ForgeMediaTokens.Colors.secondarySurface
        }
    }

    private var phaseBorderColor: Color {
        switch job.phase {
        case .running, .separating, .transcribing, .stabilizing, .preparing: return ForgeMediaTokens.Colors.borderBrand.opacity(0.6)
        case .takingLonger, .completedWithWarnings, .paused:                  return ForgeMediaTokens.Colors.warning.opacity(0.5)
        case .completed:                                                      return ForgeMediaTokens.Colors.success.opacity(0.5)
        case .failed, .canceled:                                              return ForgeMediaTokens.Colors.danger.opacity(0.5)
        default:                                                              return ForgeMediaTokens.Colors.borderSubtle
        }
    }

    private var phaseTextColor: Color {
        switch job.phase {
        case .running, .separating, .transcribing, .stabilizing, .preparing: return ForgeMediaTokens.Colors.brand
        case .takingLonger, .completedWithWarnings, .paused:                  return ForgeMediaTokens.Colors.warning
        case .completed:                                                      return ForgeMediaTokens.Colors.success
        case .failed, .canceled:                                              return ForgeMediaTokens.Colors.danger
        default:                                                              return ForgeMediaTokens.Colors.bodySubtle
        }
    }

    private var progressFill: Color {
        switch job.phase {
        case .failed:                         return ForgeMediaTokens.Colors.danger
        case .takingLonger:                   return ForgeMediaTokens.Colors.warning
        case .completed, .completedWithWarnings: return ForgeMediaTokens.Colors.success
        default:                              return ForgeMediaTokens.Colors.brand
        }
    }

    private var statusIcon: String {
        switch job.phase {
        case .completed:             return "checkmark.circle"
        case .completedWithWarnings: return "exclamationmark.triangle"
        case .failed:                return "xmark.circle"
        case .canceled:              return "xmark.circle"
        case .recovered:             return "arrow.counterclockwise.circle"
        default:                     return "info.circle"
        }
    }

    private var statusColor: Color {
        switch job.phase {
        case .completed:             return ForgeMediaTokens.Colors.success
        case .failed, .canceled:     return ForgeMediaTokens.Colors.danger
        case .completedWithWarnings: return ForgeMediaTokens.Colors.warning
        default:                     return ForgeMediaTokens.Colors.bodySubtle
        }
    }

    private var statusBg: Color {
        switch job.phase {
        case .completed:             return ForgeMediaTokens.Colors.successSoft
        case .completedWithWarnings: return ForgeMediaTokens.Colors.warningSoft
        case .failed, .canceled:     return ForgeMediaTokens.Colors.dangerSoft
        default:                     return ForgeMediaTokens.Colors.secondarySurface
        }
    }

    private var statusText: String {
        switch job.phase {
        case .completed:             return "Output saved · checksum verified"
        case .completedWithWarnings: return "Complete · minor warnings (output usable)"
        case .failed:                return "Could not read video stream — try FFmpeg engine"
        case .canceled:              return "Canceled by user"
        case .recovered:             return "Recovered from checkpoint"
        default:                     return "Unknown state"
        }
    }

    // MARK: - Icon Actions

    private struct IconAction {
        let icon: String
        let tooltip: String
        let action: () -> Void
        let isDestructive: Bool
    }

    private var iconActions: [IconAction] {
        switch job.phase {
        case .preparing, .running, .validating, .separating, .transcribing, .stabilizing:
            return [
                IconAction(icon: "pause",  tooltip: "Pause",  action: onPause,  isDestructive: false),
                IconAction(icon: "xmark",  tooltip: "Cancel", action: onCancel, isDestructive: true),
            ]
        case .completed, .completedWithWarnings:
            return [IconAction(icon: "folder", tooltip: "Open output", action: onOpenOutput, isDestructive: false)]
        case .failed:
            return [IconAction(icon: "arrow.counterclockwise", tooltip: "Retry", action: onRetry, isDestructive: false)]
        case .canceled:
            return [IconAction(icon: "arrow.counterclockwise", tooltip: "Resume", action: onRetry, isDestructive: false)]
        default:
            return []
        }
    }
}

// MARK: - Preview

#if DEBUG
struct JobCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            JobCardView(
                job: JobRecord(
                    title: "interview_4k_raw_uncompressed.mov",
                    sourceURL: URL(fileURLWithPath: "/tmp/test.mov"),
                    presetID: "restore_4k",
                    phase: .running,
                    progressFraction: 0.57,
                    progressConfidence: .measured,
                    progressLabel: "Encoding segment 3 of 6…"
                ),
                preset: MediaPreset.builtIn.first(where: { $0.id == "restore_4k" }),
                onPause: {}, onCancel: {}, onRetry: {}, onOpenOutput: {}
            )
            JobCardView(
                job: JobRecord(
                    title: "podcast_ep42_final_master.wav",
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
        .frame(width: 520)
        .padding(28)
        .background(ForgeMediaTokens.Colors.canvas)
    }
}
#endif
