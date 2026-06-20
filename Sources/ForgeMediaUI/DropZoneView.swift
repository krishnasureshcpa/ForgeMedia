import SwiftUI

/// GeexArts Premium Drop Zone
/// Features: Multi-layered glass, ambient breathing glow, fluid spring physics on drag-over.
public struct DropZoneView: View {
    @Binding public var isTargeted: Bool
    public let onDrop: ([URL]) -> Void

    @State private var isHovered: Bool = false
    @State private var breathingPhase: Double = 0.0

    public init(isTargeted: Binding<Bool>, onDrop: @escaping ([URL]) -> Void) {
        self._isTargeted = isTargeted
        self.onDrop = onDrop
    }

    public var body: some View {
        ZStack {
            // 1. Ambient Breathing Glow (behind the glass)
            Circle()
                .fill(ForgeMediaTokens.Colors.accent)
                .blur(radius: 60)
                .opacity(isTargeted ? 0.15 : (isHovered ? 0.08 : 0.04))
                .scaleEffect(isTargeted ? 1.2 : (1.0 + breathingPhase * 0.1))
                .animation(
                    Animation.easeInOut(duration: 2.4).repeatForever(autoreverses: true),
                    value: breathingPhase
                )

            // 2. Glass Surface
            VStack(spacing: 10) {
                // Icon with spring morph
                Image(systemName: isTargeted ? "tray.and.arrow.down.fill" : "tray.and.arrow.down")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(isTargeted ? ForgeMediaTokens.Colors.accent : ForgeMediaTokens.Colors.muted)
                    .scaleEffect(isTargeted ? 1.15 : 1.0)
                    .animation(ForgeMediaTokens.Motion.spring, value: isTargeted)

                Text(isTargeted ? "Release to import" : "Drop media files here")
                    .font(.system(.body, design: .default).weight(.medium))
                    .foregroundColor(isTargeted ? ForgeMediaTokens.Colors.accent : ForgeMediaTokens.Colors.fgSecondary)
                    .animation(ForgeMediaTokens.Motion.snappy, value: isTargeted)

                Text("Privacy On · files stay on your Mac")
                    .font(.system(.caption, design: .default))
                    .foregroundColor(ForgeMediaTokens.Colors.muted)
            }
            .padding(.vertical, 28)
            .padding(.horizontal, 20)
        }
        .frame(minHeight: 130)
        .background(ForgeMediaTokens.Glass.surface)
        .clipShape(RoundedRectangle(cornerRadius: ForgeMediaTokens.Radii.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ForgeMediaTokens.Radii.large, style: .continuous)
                .stroke(
                    isTargeted ? ForgeMediaTokens.Colors.accent : (isHovered ? ForgeMediaTokens.Colors.border : ForgeMediaTokens.Colors.borderSoft),
                    lineWidth: isTargeted ? 2 : 1
                )
        )
        .shadow(
            color: .black.opacity(isTargeted ? 0.15 : 0.06),
            radius: isTargeted ? 16 : 6,
            x: 0, y: isTargeted ? 8 : 2
        )
        // Fluid spring scale on drag-over
        .scaleEffect(isTargeted ? 1.006 : 1.0)
        .animation(ForgeMediaTokens.Motion.spring, value: isTargeted)
        .onHover { hovering in
            withAnimation(ForgeMediaTokens.Motion.snappy) {
                isHovered = hovering
            }
        }
        // Native macOS drag and drop
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            let urls = providers.compactMap { provider -> URL? in
                var url: URL?
                let semaphore = DispatchSemaphore(value: 0)
                _ = provider.loadObject(ofClass: URL.self) { obj, _ in
                    url = obj
                    semaphore.signal()
                }
                semaphore.wait()
                return url
            }
            if !urls.isEmpty { onDrop(urls) }
            return true
        }
        .onAppear {
            // Start the subtle breathing animation
            withAnimation(Animation.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                breathingPhase = 1.0
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct DropZoneView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            DropZoneView(isTargeted: .constant(false)) { _ in }
            DropZoneView(isTargeted: .constant(true)) { _ in }
        }
        .padding()
        .frame(width: 400)
        .background(ForgeMediaTokens.Colors.bg)
    }
}
#endif