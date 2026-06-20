import SwiftUI
import ForgeMediaDomain

/// Real-time backend activity stream.
///
/// Renders recent `JobEvent`s as a vertically scrolling feed with phase-coloured
/// icons, monospaced timestamps, and entrance animations. Designed so the user
/// can "watch the app work" — every progress callback the engine emits lands here.
public struct ActivityStreamView: View {
    public let events: [JobEvent]
    public let jobs: [JobRecord]
    public let maxVisible: Int

    @State private var pulsePhase: Double = 0

    public init(events: [JobEvent], jobs: [JobRecord], maxVisible: Int = 20) {
        self.events = events
        self.jobs = jobs
        self.maxVisible = maxVisible
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().opacity(0.4)

            if events.isEmpty {
                emptyState
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(recentEvents) { event in
                                ActivityRow(event: event, jobTitle: jobTitle(for: event.jobID))
                                    .id(event.id)
                                    .transition(
                                        .asymmetric(
                                            insertion: .move(edge: .top).combined(with: .opacity),
                                            removal: .opacity
                                        )
                                    )
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .onChange(of: events.count) { _, _ in
                        if let last = recentEvents.last {
                            withAnimation(ForgeMediaTokens.Motion.smooth) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .background(ForgeMediaTokens.Glass.base)
        .clipShape(RoundedRectangle(cornerRadius: ForgeMediaTokens.Radii.default, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ForgeMediaTokens.Radii.default, style: .continuous)
                .stroke(ForgeMediaTokens.Colors.border, lineWidth: 0.5)
        )
    }

    private var recentEvents: [JobEvent] {
        Array(events.suffix(maxVisible))
    }

    private var header: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(ForgeMediaTokens.Colors.success.opacity(0.15))
                    .frame(width: 18, height: 18)
                Circle()
                    .fill(ForgeMediaTokens.Colors.success)
                    .frame(width: 8, height: 8)
                    .scaleEffect(0.8 + 0.4 * pulsePhase)
                    .animation(Animation.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: pulsePhase)
            }
            .onAppear { pulsePhase = 1 }
            .onDisappear { pulsePhase = 0 }

            Text("Activity")
                .font(.system(.caption, design: .default).weight(.heavy))
                .foregroundColor(ForgeMediaTokens.Colors.fg)
                .tracking(0.6)

            Text("·")
                .foregroundColor(ForgeMediaTokens.Colors.muted)

            Text("\(events.count) event\(events.count == 1 ? "" : "s")")
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(ForgeMediaTokens.Colors.muted)

            Spacer()

            if let latest = events.last {
                Text(relativeTime(latest.createdAt))
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(ForgeMediaTokens.Colors.muted)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 22, weight: .light))
                .foregroundColor(ForgeMediaTokens.Colors.muted)
            Text("Awaiting first job")
                .font(.system(.caption, design: .default).weight(.medium))
                .foregroundColor(ForgeMediaTokens.Colors.muted)
            Text("Drop a video to see the activity stream")
                .font(.system(.caption2))
                .foregroundColor(ForgeMediaTokens.Colors.muted.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }

    private func jobTitle(for id: String) -> String {
        jobs.first(where: { $0.id == id })?.title ?? "Job"
    }

    private func relativeTime(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 1 { return "now" }
        if interval < 60 { return "\(Int(interval))s ago" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        return "\(Int(interval / 3600))h ago"
    }
}

/// Single row in the activity stream.
private struct ActivityRow: View {
    let event: JobEvent
    let jobTitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            phaseIcon
                .frame(width: 18, height: 18)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(phaseLabel)
                        .font(.system(.caption, design: .default).weight(.semibold))
                        .foregroundColor(phaseColor)
                        .tracking(0.4)

                    Text("·")
                        .foregroundColor(ForgeMediaTokens.Colors.muted.opacity(0.6))

                    Text(jobTitle)
                        .font(.system(.caption, design: .default))
                        .foregroundColor(ForgeMediaTokens.Colors.fg)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                if !event.message.isEmpty {
                    Text(event.message)
                        .font(.system(.caption2, design: .default))
                        .foregroundColor(ForgeMediaTokens.Colors.fgSecondary)
                        .lineLimit(2)
                }

                if let conf = event.progressConfidence {
                    let pct = Int((event.progressFraction ?? 0) * 100)
                    Text("\(pct)% · \(confidenceLabel(conf))")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(ForgeMediaTokens.Colors.muted)
                }
            }

            Spacer()

            Text(timeString(event.createdAt))
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(ForgeMediaTokens.Colors.muted)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(ForgeMediaTokens.Colors.borderSoft.opacity(0.15))
        .overlay(
            Rectangle()
                .fill(phaseColor.opacity(0.5))
                .frame(width: 2),
            alignment: .leading
        )
    }

    private var phaseLabel: String {
        event.phase.rawValue.uppercased()
    }

    private var phaseColor: Color {
        switch event.phase {
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

    private var phaseIcon: some View {
        Group {
            switch event.phase {
            case .completed:
                Image(systemName: "checkmark.circle.fill").foregroundColor(phaseColor)
            case .failed:
                Image(systemName: "xmark.octagon.fill").foregroundColor(phaseColor)
            case .running:
                ProgressView().controlSize(.small).scaleEffect(0.7)
            case .preparing, .validating:
                Image(systemName: "arrow.triangle.2.circlepath").foregroundColor(phaseColor)
            case .canceled:
                Image(systemName: "xmark.circle.fill").foregroundColor(phaseColor)
            case .paused:
                Image(systemName: "pause.circle.fill").foregroundColor(phaseColor)
            case .recovered:
                Image(systemName: "arrow.counterclockwise.circle.fill").foregroundColor(phaseColor)
            case .completedWithWarnings:
                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(phaseColor)
            default:
                Image(systemName: "circle.fill").foregroundColor(phaseColor)
            }
        }
        .font(.system(size: 14))
    }

    private func confidenceLabel(_ c: ProgressConfidence) -> String {
        switch c {
        case .measured: return "measured"
        case .estimated: return "estimated"
        case .validating: return "validating"
        case .unknown: return "unknown"
        }
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}