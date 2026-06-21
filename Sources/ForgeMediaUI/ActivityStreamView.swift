import SwiftUI
import ForgeMediaDomain

/// Real-time backend activity stream — neo-brutalist styled.
///
/// Visual language: cream background with grid texture · 4px black border ·
/// rows with a thick left color strip per phase · bold uppercase labels ·
/// hard shadow on hover · no blur · no soft backgrounds.
public struct ActivityStreamView: View {
    public let events: [JobEvent]
    public let jobs: [JobRecord]
    public let maxVisible: Int

    public init(events: [JobEvent], jobs: [JobRecord], maxVisible: Int = 20) {
        self.events = events
        self.jobs = jobs
        self.maxVisible = maxVisible
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            streamHeader

            // Thick separator — neo-brutalist divider
            Rectangle()
                .fill(Color.black)
                .frame(height: 3)

            ZStack {
                // Grid texture sits behind all rows
                ForgeMediaTokens.Colors.canvas
                GridPatternView(cellSize: 28, lineOpacity: 0.06)

                if events.isEmpty {
                    emptyState
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(recentEvents) { event in
                                    ActivityRow(
                                        event: event,
                                        jobTitle: jobTitle(for: event.jobID)
                                    )
                                    .id(event.id)
                                    .transition(
                                        .asymmetric(
                                            insertion: .move(edge: .bottom).combined(with: .opacity),
                                            removal: .opacity
                                        )
                                    )
                                    Divider().opacity(0.3)
                                }
                            }
                            .padding(.vertical, 4)
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
        }
        // Neo card: cream fill · 4px black border · hard shadow
        .background(ForgeMediaTokens.Colors.canvas)
        .clipShape(Rectangle())
        .overlay(Rectangle().stroke(Color.black, lineWidth: 4))
        .shadow(color: .black, radius: 0, x: 6, y: 6)
    }

    // MARK: - Sub-views

    private var streamHeader: some View {
        HStack(spacing: 10) {
            // "Live" indicator — neo pill with black border
            HStack(spacing: 5) {
                Circle()
                    .fill(events.isEmpty
                          ? Color.black.opacity(0.30)
                          : ForgeMediaTokens.Colors.success)
                    .frame(width: 7, height: 7)
                Text("ACTIVITY")
                    .font(.system(size: 11, weight: .black))
                    .tracking(2)
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(ForgeMediaTokens.Colors.secondary)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.black, lineWidth: 2))

            Text("·")
                .font(.system(size: 14, weight: .black))
                .foregroundColor(.black.opacity(0.30))

            Text("\(events.count) event\(events.count == 1 ? "" : "s")")
                .font(.system(.caption2, design: .monospaced).weight(.bold))
                .foregroundColor(.black.opacity(0.55))

            Spacer()

            if let latest = events.last {
                Text(relativeTime(latest.createdAt).uppercased())
                    .font(.system(.caption2, design: .monospaced).weight(.bold))
                    .tracking(1)
                    .foregroundColor(.black.opacity(0.45))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            // Decorative bordered icon
            ZStack {
                Rectangle()
                    .fill(ForgeMediaTokens.Colors.canvas)
                    .frame(width: 48, height: 48)
                    .overlay(Rectangle().stroke(Color.black, lineWidth: 3))
                    .shadow(color: .black, radius: 0, x: 4, y: 4)
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(.black)
            }

            Text("NO ACTIVITY YET")
                .font(.system(size: 11, weight: .black))
                .tracking(2.5)
                .foregroundColor(.black.opacity(0.55))

            Text("Drop a video to see the activity stream")
                .font(.system(.caption2).weight(.bold))
                .foregroundColor(.black.opacity(0.40))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 32)
    }

    // MARK: - Helpers

    private var recentEvents: [JobEvent] { Array(events.suffix(maxVisible)) }

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

// MARK: - Activity Row

private struct ActivityRow: View {
    let event: JobEvent
    let jobTitle: String

    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .top, spacing: 0) {

            // Thick left phase-color strip — visual anchor
            Rectangle()
                .fill(phaseColor)
                .frame(width: 4)

            HStack(alignment: .top, spacing: 10) {
                // Phase icon in a tiny bordered square
                ZStack {
                    Rectangle()
                        .fill(phaseColor.opacity(0.15))
                        .frame(width: 22, height: 22)
                        .overlay(Rectangle().stroke(phaseColor, lineWidth: 1.5))
                    phaseIcon
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(phaseLabel)
                            .font(.system(.caption, design: .default).weight(.black))
                            .tracking(1.5)
                            .foregroundColor(.black)

                        Text("·")
                            .foregroundColor(.black.opacity(0.30))

                        Text(jobTitle)
                            .font(.system(.caption, design: .default).weight(.bold))
                            .foregroundColor(.black.opacity(0.65))
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    if !event.message.isEmpty {
                        Text(event.message)
                            .font(.system(.caption2, design: .default).weight(.bold))
                            .foregroundColor(.black.opacity(0.55))
                            .lineLimit(2)
                    }

                    if let conf = event.progressConfidence {
                        let pct = Int((event.progressFraction ?? 0) * 100)
                        Text("\(pct)% · \(confidenceLabel(conf).uppercased())")
                            .font(.system(.caption2, design: .monospaced).weight(.bold))
                            .tracking(0.5)
                            .foregroundColor(.black.opacity(0.40))
                    }
                }

                Spacer()

                Text(timeString(event.createdAt))
                    .font(.system(.caption2, design: .monospaced).weight(.bold))
                    .foregroundColor(.black.opacity(0.40))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
        }
        .background(isHovered ? ForgeMediaTokens.Colors.canvas : Color.white)
        .animation(ForgeMediaTokens.Motion.snap, value: isHovered)
        .onHover { isHovered = $0 }
    }

    // MARK: Phase helpers

    private var phaseLabel: String { event.phase.rawValue.uppercased() }

    private var phaseColor: Color {
        switch event.phase {
        case .idle, .canceled, .probing, .planning:
            return .black.opacity(0.30)
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

    private var phaseIcon: some View {
        Group {
            switch event.phase {
            case .completed:
                Image(systemName: "checkmark").foregroundColor(phaseColor)
            case .failed:
                Image(systemName: "xmark").foregroundColor(phaseColor)
            case .running:
                ProgressView().controlSize(.mini).scaleEffect(0.7)
            case .preparing, .validating:
                Image(systemName: "arrow.triangle.2.circlepath").foregroundColor(phaseColor)
            case .canceled:
                Image(systemName: "xmark").foregroundColor(phaseColor)
            case .paused:
                Image(systemName: "pause").foregroundColor(phaseColor)
            case .recovered:
                Image(systemName: "arrow.counterclockwise").foregroundColor(phaseColor)
            case .completedWithWarnings:
                Image(systemName: "exclamationmark").foregroundColor(phaseColor)
            default:
                Image(systemName: "circle.fill").foregroundColor(phaseColor)
            }
        }
        .font(.system(size: 11, weight: .black))
    }

    private func confidenceLabel(_ c: ProgressConfidence) -> String {
        switch c {
        case .measured:   return "measured"
        case .estimated:  return "estimated"
        case .validating: return "validating"
        case .unknown:    return "unknown"
        }
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f.string(from: date)
    }
}
