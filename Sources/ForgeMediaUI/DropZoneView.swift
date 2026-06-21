import SwiftUI

/// Retro media intake drop zone.
///
/// At rest: cream (#FFEEDD) + dashed 1px taupe border.
/// Targeted: soft orange fill (#FFF1EB) + solid 1px brand border.
/// No thick borders, no hard offset shadows — surgical 1px retro chrome.
public struct DropZoneView: View {
    @Binding public var isTargeted: Bool
    public let onDrop: ([URL]) -> Void

    @State private var isHovered = false

    public init(isTargeted: Binding<Bool>, onDrop: @escaping ([URL]) -> Void) {
        self._isTargeted = isTargeted
        self.onDrop = onDrop
    }

    public var body: some View {
        ZStack {
            // Background fill
            RoundedRectangle(cornerRadius: 3)
                .fill(isTargeted
                      ? ForgeMediaTokens.Colors.brandSofter
                      : ForgeMediaTokens.Colors.canvas)

            // Content
            VStack(spacing: 16) {
                iconShape
                labels
                privacyTag
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
        }
        .frame(minHeight: 130)
        // Border — dashed at rest, solid on targeted/hover
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(
                    style: StrokeStyle(
                        lineWidth: 1,
                        dash: (isTargeted || isHovered) ? [] : [6, 4]
                    )
                )
                .foregroundColor(
                    isTargeted
                    ? ForgeMediaTokens.Colors.borderBrand
                    : isHovered
                        ? ForgeMediaTokens.Colors.borderDefault
                        : ForgeMediaTokens.Colors.borderDefault
                )
        )
        .offset(y: isTargeted ? -2 : (isHovered ? -1 : 0))
        .animation(ForgeMediaTokens.Motion.snappy, value: isTargeted)
        .animation(ForgeMediaTokens.Motion.snappy, value: isHovered)
        .onHover { isHovered = $0 }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            let collector = DropURLCollector()
            let group = DispatchGroup()
            for provider in providers {
                group.enter()
                _ = provider.loadObject(ofClass: URL.self) { obj, _ in
                    if let obj { collector.append(obj) }
                    group.leave()
                }
            }
            group.notify(queue: .main) {
                let urls = collector.snapshot()
                if !urls.isEmpty { onDrop(urls) }
            }
            return true
        }
    }

    // MARK: - Sub-views

    private var iconShape: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(isTargeted
                      ? ForgeMediaTokens.Colors.brandSoft
                      : ForgeMediaTokens.Colors.brandSofter)
                .frame(width: 44, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(
                            isTargeted
                            ? ForgeMediaTokens.Colors.borderBrand
                            : ForgeMediaTokens.Colors.borderSubtle,
                            lineWidth: 1
                        )
                )

            Image(systemName: isTargeted ? "film.stack.fill" : "film.stack")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(
                    isTargeted
                    ? ForgeMediaTokens.Colors.brand
                    : ForgeMediaTokens.Colors.bodySubtle
                )
        }
        .animation(ForgeMediaTokens.Motion.snap, value: isTargeted)
    }

    private var labels: some View {
        VStack(spacing: 5) {
            Text(isTargeted ? "Release to import" : "MOUNT PATH: Drop media files here")
                .font(.system(size: 13, weight: .semibold, design: .serif))
                .foregroundColor(ForgeMediaTokens.Colors.heading)
                .multilineTextAlignment(.center)

            Text(isTargeted
                 ? "Files stay on your Mac"
                 : "or select from the toolbar above")
                .font(.system(size: 12))
                .foregroundColor(ForgeMediaTokens.Colors.bodySubtle)
        }
    }

    private var privacyTag: some View {
        HStack(spacing: 5) {
            Image(systemName: "lock.fill")
                .font(.system(size: 9, weight: .medium))
            Text("FILES STAY LOCAL")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .tracking(0.8)
        }
        .foregroundColor(ForgeMediaTokens.Colors.brand)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(ForgeMediaTokens.Colors.brandSofter)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(ForgeMediaTokens.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

private final class DropURLCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var urls: [URL] = []
    func append(_ url: URL) { lock.lock(); urls.append(url); lock.unlock() }
    func snapshot() -> [URL] { lock.lock(); let v = urls; lock.unlock(); return v }
}

#if DEBUG
struct DropZoneView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 32) {
            DropZoneView(isTargeted: .constant(false)) { _ in }
            DropZoneView(isTargeted: .constant(true)) { _ in }
        }
        .padding(32)
        .frame(width: 480)
        .background(ForgeMediaTokens.Colors.canvas)
    }
}
#endif
