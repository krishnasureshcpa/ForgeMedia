import SwiftUI

// MARK: - Nostalgia Design Tokens
//
// Warm toasted-cream surfaces · espresso-brown ink · glowing orange accent.
// Retro macOS desktop-OS aesthetic: sharp 3px corners, 1px taupe borders,
// flat chrome + physical inset-press buttons, warm directional shadows.
// Light: sun-faded vintage manual · Dark: CRT terminal at night.

// Internal hex colour init — accessible throughout ForgeMediaUI, not exported.
extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var v: UInt64 = 0
        Scanner(string: h).scanHexInt64(&v)
        self.init(
            red:   Double((v >> 16) & 0xFF) / 255,
            green: Double((v >>  8) & 0xFF) / 255,
            blue:  Double( v        & 0xFF) / 255
        )
    }
}

public struct ForgeMediaTokens {

    // MARK: - Colors
    public struct Colors {

        // ── Canvas & Surfaces ─────────────────────────────────────────────────
        /// Toasted cream — main window / card background.
        public static let canvas            = Color(hex: "#FFEEDD")
        /// Fixed top menu-bar surface.
        public static let menuBar           = Color(hex: "#E5D4C5")
        /// Alternating / inset panel surfaces.
        public static let secondarySurface  = Color(hex: "#F6E6D6")
        /// Recessed input / hover-row background.
        public static let inputBg           = Color(hex: "#DBC8B6")

        // ── Typography ────────────────────────────────────────────────────────
        /// Espresso headings.
        public static let heading           = Color(hex: "#381C00")
        /// Body text.
        public static let body              = Color(hex: "#4A3826")
        /// Subtle captions, meta, timestamps.
        public static let bodySubtle        = Color(hex: "#6C5945")

        // ── Brand Orange ──────────────────────────────────────────────────────
        /// Signature glowing orange — primary CTAs, wallpaper accent.
        public static let brand             = Color(hex: "#FF631A")
        /// Soft orange — hover / targeted state fills.
        public static let brandSoft         = Color(hex: "#FFD2B8")
        /// Very soft orange — subtle backgrounds.
        public static let brandSofter       = Color(hex: "#FFF1EB")
        /// Medium brand — selected / elevated state.
        public static let brandMedium       = Color(hex: "#FFBA94")

        // ── Buttons ───────────────────────────────────────────────────────────
        /// Primary fill: espresso dark.
        public static let buttonPrimary     = Color(hex: "#3F1400")
        /// Secondary fill: rust.
        public static let buttonSecondary   = Color(hex: "#9D3200")
        /// Tertiary fill: taupe-brown.
        public static let buttonTertiary    = Color(hex: "#8D6C5D")

        // ── Borders ───────────────────────────────────────────────────────────
        /// Workhorse 1px taupe-brown border.
        public static let borderDefault     = Color(hex: "#8D6C5D")
        /// Subtle secondary border.
        public static let borderSubtle      = Color(hex: "#C3A98E")
        /// Strong border for active / focused.
        public static let borderStrong      = Color(hex: "#3F1400")
        /// Brand-tinted border.
        public static let borderBrand       = Color(hex: "#FF631A")

        // ── Status ────────────────────────────────────────────────────────────
        public static let success           = Color(hex: "#2F6C2D")
        public static let successSoft       = Color(hex: "#E2F4DB")
        public static let danger            = Color(hex: "#B0300A")
        public static let dangerSoft        = Color(hex: "#FFF1EB")
        public static let warning           = Color(hex: "#C2410C")
        public static let warningSoft       = Color(hex: "#FFEFD6")

        // ── Terminal / Code ───────────────────────────────────────────────────
        /// Dark code-pane background.
        public static let codeBg            = Color(hex: "#2B1B11")
        /// Warm cream code text.
        public static let codeText          = Color(hex: "#FFE6D1")
        /// Slightly dim code text for secondary log lines.
        public static let codeTextSubtle    = Color(hex: "#C3AB97")

        // ── White ─────────────────────────────────────────────────────────────
        /// Near-white warm cream (used for button text on dark fills).
        public static let white             = Color(hex: "#FFF6EE")

        // ── Legacy Aliases (preserve all existing call sites) ─────────────────
        public static let bg            = canvas
        public static let fg            = heading
        public static let fgSecondary   = body
        public static let muted         = bodySubtle
        public static let ink           = heading
        public static let border        = borderDefault
        public static let borderSoft    = borderSubtle
        public static let accent        = brand
        public static let accentStrong  = Color(hex: "#D94A00")
        public static let secondary     = menuBar
        public static let neomuted      = brandSoft
        public static let teal          = Color(hex: "#2F9B9B")
        public static let accentGlow    = brandSofter
        public static let warningGlow   = warningSoft
        public static let dangerGlow    = dangerSoft
        public static let tealGlow      = Color(hex: "#2F9B9B").opacity(0.15)
    }

    // MARK: - Radii — 3px max. Pill only for explicit badge / capsule shapes.
    public struct Radii {
        public static let sharp: CGFloat     = 0    // absolute hard corners
        public static let compact: CGFloat   = 3    // controls, cards, inputs
        public static let `default`: CGFloat = 3
        public static let large: CGFloat     = 3
        public static let pill: CGFloat      = 980  // badge / chip shapes
    }

    // MARK: - Shadows — warm espresso-tinted directional elevation.
    public struct ShadowSpec: Sendable {
        public let color: Color
        public let radius: CGFloat
        public let x: CGFloat
        public let y: CGFloat

        public init(_ color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            self.color = color; self.radius = radius; self.x = x; self.y = y
        }
    }

    public struct Shadow {
        private static let e = Color(red: 56/255, green: 28/255, blue: 0/255)

        /// First layer of the floating window shadow.
        public static let windowLo  = ShadowSpec(e.opacity(0.18), radius: 10, x: 0, y: 4)
        /// Second layer of the floating window shadow.
        public static let windowHi  = ShadowSpec(e.opacity(0.28), radius: 38, x: 0, y: 20)
        /// Dropdown / popover / tooltip shadow.
        public static let menu      = ShadowSpec(e.opacity(0.15), radius: 16, x: 0, y: 5)

        // Legacy shape names (keep old call sites compiling)
        public static let small     = menu
        public static let medium    = menu
        public static let large     = windowLo
        public static let massive   = windowHi
        public static let lifted    = ShadowSpec(e.opacity(0.22), radius: 12, x: 0, y: 6)
    }

    // MARK: - Motion — 120ms ease-out base. No linear snaps, no bouncy springs.
    public struct Motion {
        public static let snap      = Animation.linear(duration: 0.08)
        public static let snappy    = Animation.easeOut(duration: 0.12)
        public static let spring    = Animation.easeOut(duration: 0.15)
        public static let smooth    = Animation.easeOut(duration: 0.20)
        public static let cardEnter = Animation.easeOut(duration: 0.18)
    }

    // MARK: - Glass (legacy — maps to warm canvas surfaces)
    public struct Glass {
        public static let base: Color     = Colors.canvas
        public static let surface: Color  = Colors.canvas
        public static let elevated: Color = Colors.secondarySurface
        public static let floating: Color = Colors.canvas
    }
}

// MARK: - View Extensions

public extension View {

    /// Nostalgia window card: cream fill · 1px taupe border · 3px radius · warm shadow.
    func forgeWindowCard(isElevated: Bool = false) -> some View {
        self
            .background(ForgeMediaTokens.Colors.canvas)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(ForgeMediaTokens.Colors.borderDefault, lineWidth: 1)
            )
            .shadow(
                color: ForgeMediaTokens.Shadow.windowLo.color,
                radius: ForgeMediaTokens.Shadow.windowLo.radius,
                x: ForgeMediaTokens.Shadow.windowLo.x,
                y: ForgeMediaTokens.Shadow.windowLo.y
            )
            .shadow(
                color: ForgeMediaTokens.Shadow.windowHi.color,
                radius: ForgeMediaTokens.Shadow.windowHi.radius,
                x: ForgeMediaTokens.Shadow.windowHi.x,
                y: ForgeMediaTokens.Shadow.windowHi.y
            )
    }

    /// Legacy alias.
    func forgeGlassCard(isElevated: Bool = false) -> some View {
        forgeWindowCard(isElevated: isElevated)
    }

    /// Primary button quick modifier.
    func forgePrimaryButton() -> some View {
        self
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(ForgeMediaTokens.Colors.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(ForgeMediaTokens.Colors.buttonPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(ForgeMediaTokens.Colors.borderStrong, lineWidth: 1)
            )
    }

    /// Very subtle halftone dot texture on cream.
    func forgeHalftoneTexture(dotSize: CGFloat = 1.5, spacing: CGFloat = 18, opacity: Double = 0.04) -> some View {
        overlay(HalftonePatternView(dotSize: dotSize, spacing: spacing, dotOpacity: opacity))
    }

    /// Very subtle grid line texture on cream.
    func forgeGridTexture(cellSize: CGFloat = 28, opacity: Double = 0.04) -> some View {
        overlay(GridPatternView(cellSize: cellSize, lineOpacity: opacity))
    }

    /// Apply a ShadowSpec as a modifier.
    func forgeHardShadow(_ spec: ForgeMediaTokens.ShadowSpec) -> some View {
        shadow(color: spec.color, radius: spec.radius, x: spec.x, y: spec.y)
    }
}

// MARK: - ForgeButtonStyle — flat retro key with physical press.

/// Nostalgia flat button. Press = 1px down-shift (physical key feel).
/// Variant maps directly to design-system button hierarchy.
public struct ForgeButtonStyle: ButtonStyle {
    public enum Variant {
        case primary    // espresso fill + cream text
        case secondary  // rust fill + cream text
        case outline    // cream bg + taupe border
        case ghost      // transparent, no border
    }

    private let variant: Variant

    public init(_ variant: Variant = .outline) {
        self.variant = variant
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(fg)
            .lineLimit(1)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(bg(pressed: configuration.isPressed))
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(border, lineWidth: variant == .ghost ? 0 : 1)
            )
            .offset(y: configuration.isPressed ? 1 : 0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }

    private var fg: Color {
        switch variant {
        case .primary, .secondary: return ForgeMediaTokens.Colors.white
        case .outline, .ghost:     return ForgeMediaTokens.Colors.heading
        }
    }

    private func bg(pressed: Bool) -> Color {
        let dim: Double = pressed ? 0.82 : 1.0
        switch variant {
        case .primary:   return ForgeMediaTokens.Colors.buttonPrimary.opacity(dim)
        case .secondary: return ForgeMediaTokens.Colors.buttonSecondary.opacity(dim)
        case .outline:   return pressed ? ForgeMediaTokens.Colors.inputBg : ForgeMediaTokens.Colors.canvas
        case .ghost:     return pressed ? ForgeMediaTokens.Colors.inputBg : Color.clear
        }
    }

    private var border: Color {
        switch variant {
        case .primary:   return ForgeMediaTokens.Colors.borderStrong
        case .secondary: return ForgeMediaTokens.Colors.borderStrong
        case .outline:   return ForgeMediaTokens.Colors.borderDefault
        case .ghost:     return Color.clear
        }
    }
}

/// Legacy name — all old NeoBrutalButtonStyle call sites now produce Nostalgia buttons.
public typealias NeoBrutalButtonStyle = ForgeButtonStyle

// MARK: - Texture Views

/// Light espresso-toned grid — used as subtle paper texture on cream.
public struct GridPatternView: View {
    let cellSize: CGFloat
    let lineOpacity: Double

    public init(cellSize: CGFloat = 28, lineOpacity: Double = 0.04) {
        self.cellSize = cellSize
        self.lineOpacity = lineOpacity
    }

    public var body: some View {
        Canvas { context, size in
            let ink = GraphicsContext.Shading.color(
                Color(red: 56/255, green: 28/255, blue: 0).opacity(lineOpacity)
            )
            stride(from: 0 as CGFloat, through: size.width, by: cellSize).forEach { x in
                var p = Path(); p.move(to: .init(x: x, y: 0)); p.addLine(to: .init(x: x, y: size.height))
                context.stroke(p, with: ink, lineWidth: 0.5)
            }
            stride(from: 0 as CGFloat, through: size.height, by: cellSize).forEach { y in
                var p = Path(); p.move(to: .init(x: 0, y: y)); p.addLine(to: .init(x: size.width, y: y))
                context.stroke(p, with: ink, lineWidth: 0.5)
            }
        }
        .allowsHitTesting(false)
    }
}

/// Light espresso-toned halftone dots — subtle tactile texture on cream.
public struct HalftonePatternView: View {
    let dotSize: CGFloat
    let spacing: CGFloat
    let dotOpacity: Double

    public init(dotSize: CGFloat = 1.5, spacing: CGFloat = 18, dotOpacity: Double = 0.04) {
        self.dotSize = dotSize
        self.spacing = spacing
        self.dotOpacity = dotOpacity
    }

    public var body: some View {
        Canvas { context, size in
            let ink = GraphicsContext.Shading.color(
                Color(red: 56/255, green: 28/255, blue: 0).opacity(dotOpacity)
            )
            stride(from: spacing / 2, to: size.height, by: spacing).forEach { row in
                stride(from: spacing / 2, to: size.width, by: spacing).forEach { col in
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: col - dotSize / 2, y: row - dotSize / 2,
                            width: dotSize, height: dotSize
                        )),
                        with: ink
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}
