import SwiftUI

/// ForgeMedia media intake drop zone — neo-brutalist styled.
///
/// Visual language: cream/white solid background · halftone dot texture ·
/// thick black border that intensifies on hover · yellow fill on drag-over ·
/// hard offset shadow · bold uppercase labels. No blur. No soft glow.
public struct DropZoneView: View {
    @Binding public var isTargeted: Bool
    public let onDrop: ([URL]) -> Void

    @State private var isHovered: Bool = false

    public init(isTargeted: Binding<Bool>, onDrop: @escaping ([URL]) -> Void) {
        self._isTargeted = isTargeted
        self.onDrop = onDrop
    }

    public var body: some View {
        ZStack {
            // ── 1. Background fill ────────────────────────────────────────────
            // Yellow when targeted (drag-over), cream otherwise.
            Rectangle()
                .fill(isTargeted ? ForgeMediaTokens.Colors.secondary : ForgeMediaTokens.Colors.canvas)

            // Halftone dot texture overlay — always visible, adds tactile depth
            HalftonePatternView(dotSize: 1.5, spacing: 20, dotOpacity: isTargeted ? 0.12 : 0.08)

            // ── 2. Content ────────────────────────────────────────────────────
            VStack(spacing: 14) {

                // Bordered icon square — sticker aesthetic
                ZStack {
                    Rectangle()
                        .fill(isTargeted ? Color.black : Color.white)
                        .frame(width: 54, height: 54)
                        .overlay(Rectangle().stroke(Color.black, lineWidth: 4))
                        .shadow(color: .black, radius: 0,
                                x: isTargeted ? 0 : 4, y: isTargeted ? 0 : 4)
                        .offset(x: isTargeted ? 3 : 0, y: isTargeted ? 3 : 0)

                    Image(systemName: isTargeted ? "film.stack.fill" : "film.stack")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(isTargeted ? .white : .black)
                }
                .animation(ForgeMediaTokens.Motion.snap, value: isTargeted)

                // Primary label
                Text(isTargeted ? "RELEASE TO IMPORT" : "DROP MEDIA HERE")
                    .font(.system(size: 13, weight: .black))
                    .tracking(2)
                    .foregroundColor(.black)

                // Privacy sub-label — styled as a sticker tag
                HStack(spacing: 5) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9, weight: .black))
                    Text("PRIVACY ON · FILES STAY ON YOUR MAC")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.5)
                }
                .foregroundColor(.black)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(ForgeMediaTokens.Colors.success)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.black, lineWidth: 2))
                .rotationEffect(.degrees(-1))
            }
            .padding(.vertical, 28)
            .padding(.horizontal, 24)
        }
        .frame(minHeight: 130)
        .clipShape(Rectangle())
        // Border intensifies on hover/targeted — snaps instantly
        .overlay(
            Rectangle().stroke(Color.black,
                               lineWidth: isHovered || isTargeted ? 4 : 2)
        )
        // Hard offset shadow grows on interaction
        .shadow(
            color: .black, radius: 0,
            x: isTargeted ? 8 : (isHovered ? 6 : 4),
            y: isTargeted ? 8 : (isHovered ? 6 : 4)
        )
        // Slight lift on hover/targeted
        .offset(y: isTargeted ? -4 : (isHovered ? -2 : 0))
        .animation(ForgeMediaTokens.Motion.snappy, value: isTargeted)
        .animation(ForgeMediaTokens.Motion.snappy, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        // Native macOS drag and drop
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
}

private final class DropURLCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var urls: [URL] = []

    func append(_ url: URL) { lock.lock(); urls.append(url); lock.unlock() }
    func snapshot() -> [URL] { lock.lock(); let v = urls; lock.unlock(); return v }
}

// MARK: - Preview

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
