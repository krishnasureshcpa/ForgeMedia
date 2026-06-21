import SwiftUI
import ForgeMediaDomain

/// Real-time backend activity stream — dark CRT terminal aesthetic.
///
/// Title bar: menu-bar surface (warm cream) · "ACTIVITY STREAM" label · live dot.
/// Body: code-bg (#2B1B11) dark terminal · warm cream monospace rows.
/// Each row: timestamp (orange) · phase label (colored) · message · progress.
public struct ActivityStreamView: View {
    public let events: [JobEvent]
    public let jobs: [JobRecord]
    public let maxVisible: Int

    public init(events: [JobEvent], jobs: [JobRecord], maxVisible: Int = 40) {
        self.events = events
        self.jobs = jobs
        self.maxVisible = maxVisible
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            streamHeader
            Divider().overlay(ForgeMediaTokens.Colors.borderDefault)
            terminalBody
        }
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(ForgeMediaTokens.Colors.borderDefault, lineWidth: 1)
        )
    }

    // MARK: - Title Bar

    private var streamHeader: some View {
        HStack(spacing: 8) {
            // Live indicator dot
            Circle()
                .fill(events.isEmpty
                      ? ForgeMediaTokens.Colors.borderSubtle
                      : ForgeMediaTokens.Colors.brand)
                .frame(width: 7, height: 7)

            Text("ACTIVITY STREAM")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .tracking(0.8)
                .foregroundColor(ForgeMediaTokens.Colors.heading)

            if !events.isEmpty {
                Text("·")
                    .foregroundColor(ForgeMediaTokens.Colors.borderDefault)
                Text("\(events.count)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(ForgeMediaTokens.Colors.bodySubtle)
            }

            Spacer()

            if let latest = events.last {
                Text(relativeTime(latest.createdAt))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(ForgeMediaTokens.Colors.bodySubtle)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 32)
        .background(ForgeMediaTokens.Colors.menuBar)
    }

    // MARK: - Terminal Body

    private var terminalBody: some View {
        ZStack {
            ForgeMediaTokens.Colors.codeBg

            if events.isEmpty {
                emptyState
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(recentEvents) { event in
                                TerminalRow(
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
                                Divider()
                                    .overlay(
                                        ForgeMediaTokens.Colors.codeText.opacity(0.07)
                                    )
                            }
                        }
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

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "terminal")
                .font(.system(size: 22))
                .foregroundColor(ForgeMediaTokens.Colors.codeText.opacity(0.30))

            Text("No activity yet")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(ForgeMediaTokens.Colors.codeText.opacity(0.35))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Helpers

    private var recentEvents: [JobEvent] { Array(events.suffix(maxVisible)) }

    private func jobTitle(for id: String) -> String {
        jobs.first(where: { $0.id == id })?.title ?? "Job"
    }

    private func relativeTime(_ date: Date) -> String {
        let d = Date().timeIntervalSince(date)
        if d < 1 { return "now" }
        if d < 60 { return "\(Int(d))s ago" }
        if d < 3600 { return "\(Int(d / 60))m ago" }
        return "\(Int(d / 3600))h ago"
    }
}

// MARK: - Terminal Row

private struct TerminalRow: View {
    let event: JobEvent
    let jobTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Header line: timestamp · phase · filename
            HStack(spacing: 6) {
                Text(timeString(event.createdAt))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(ForgeMediaTokens.Colors.brand.opacity(0.85))

                Text(phaseLabel)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .tracking(0.5)
                    .foregroundColor(phaseColor)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(phaseColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 2))

                Text(jobTitle)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(ForgeMediaTokens.Colors.codeText.opacity(0.65))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            // Message line
            if !event.message.isEmpty {
                Text("> \(event.message)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(ForgeMediaTokens.Colors.codeText.opacity(0.80))
                    .lineLimit(2)
            }

            // Progress line
            if let conf = event.progressConfidence {
                let pct = Int((event.progressFraction ?? 0) * 100)
                Text("\(pct)% · \(confidenceLabel(conf))")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(ForgeMediaTokens.Colors.codeTextSubtle.opacity(0.55))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
    }

    private var phaseLabel: String { event.phase.rawValue.uppercased() }

    private var phaseColor: Color {
        switch event.phase {
        case .idle, .canceled, .probing, .planning:
            return ForgeMediaTokens.Colors.codeTextSubtle
        case .preparing, .running, .separating, .transcribing, .stabilizing:
            return ForgeMediaTokens.Colors.brand
        case .takingLonger:
            return ForgeMediaTokens.Colors.warning
        case .validating:
            return ForgeMediaTokens.Colors.brandMedium
        case .completed:
            return ForgeMediaTokens.Colors.success
        case .completedWithWarnings, .paused:
            return ForgeMediaTokens.Colors.warning
        case .failed:
            return ForgeMediaTokens.Colors.danger
        case .recovered:
            return ForgeMediaTokens.Colors.teal
        }
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

