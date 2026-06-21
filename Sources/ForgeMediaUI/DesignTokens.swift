import SwiftUI

// MARK: - ForgeMedia Neo-Brutalist Design Tokens
//
// Design philosophy: thick black borders · hard offset shadows (zero blur) ·
// cream canvas · pop palette (hot red / vivid yellow / soft violet) ·
// mechanical snap interactions · no gradients · no blur · no subtle grays.
//
// Every element has visual weight and structural presence.
// If it doesn't have a border, it doesn't exist.

public struct ForgeMediaTokens {

    // MARK: Solid Fill Tiers
    // Neo-brutalism forbids blur/translucency.
    // These were Material.*; they are now flat Color values.
    public struct Glass {
        public static let base: Color     = Colors.canvas  // aged paper background
        public static let surface: Color  = Color.white    // card/panel fill
        public static let elevated: Color = Color.white    // elevated panel fill
        public static let floating: Color = Color.white    // modal/overlay fill
    }

    // MARK: Colors
    public struct Colors {
        // ── Canvas & Ink ──────────────────────────────────────────────────────
        /// Aged newsprint background — softer than stark white, more authentic.
        public static let canvas     = Color(red: 1.000, green: 0.992, blue: 0.961) // #FFFDF5
        /// Pure structural black — ALL text, borders, shadows. No grays.
        public static let ink        = Color.black
        public static let white      = Color.white

        // ── Neo Pop Palette ───────────────────────────────────────────────────
        /// Hot Red — primary CTA, important badges, active states.
        public static let accent     = Color(red: 1.000, green: 0.420, blue: 0.420) // #FF6B6B
        /// Vivid Yellow — secondary actions, focus states, footer background.
        public static let secondary  = Color(red: 1.000, green: 0.851, blue: 0.239) // #FFD93D
        /// Soft Violet — tertiary panels, subtle fills, decorative elements.
        public static let neomuted   = Color(red: 0.769, green: 0.710, blue: 0.992) // #C4B5FD

        // ── State Signals (high-saturation, neo-appropriate) ──────────────────
        public static let success    = Color(red: 0.161, green: 0.784, blue: 0.420) // vivid green
        public static let warning    = Color(red: 1.000, green: 0.600, blue: 0.000) // vivid orange
        public static let danger     = Color(red: 1.000, green: 0.420, blue: 0.420) // same as accent
        public static let teal       = Color(red: 0.039, green: 0.745, blue: 0.706) // vivid teal

        // ── Legacy Aliases
        // All existing call sites resolve through these.
        // Mapped to neo-brutalist equivalents — no silent style regressions.
        public static let bg            = canvas
        public static let fg            = ink
        public static let fgSecondary   = Color.black.opacity(0.62)
        public static let muted         = Color.black.opacity(0.40)
        public static let border        = Color.black
        public static let borderSoft    = Color.black.opacity(0.22)
        public static let accentStrong  = accent
        /// Yellow tint — used for focused/active state backgrounds.
        public static let accentGlow    = secondary.opacity(0.35)
        public static let warningGlow   = warning.opacity(0.18)
        public static let dangerGlow    = danger.opacity(0.18)
        public static let tealGlow      = teal.opacity(0.18)
    }

    // MARK: Geometry — Sharp by default; pill only for badge/capsule elements.
    public struct Radii {
        public static let sharp: CGFloat    = 0    // neo default — hard corners
        public static let compact: CGFloat  = 0    // was 8
        public static let `default`: CGFloat = 0   // was 12
        public static let large: CGFloat    = 0    // was 18
        public static let pill: CGFloat     = 980  // capsule badges — still allowed
    }

    // MARK: Hard Shadow Specs — zero blur, ink blocks offset bottom-right.
    public struct ShadowSpec: Sendable {
        public let color: Color
        public let radius: CGFloat
        public let x: CGFloat
        public let y: CGFloat

        public init(_ color: Color = .black, radius: CGFloat = 0, x: CGFloat, y: CGFloat) {
            self.color = color; self.radius = radius; self.x = x; self.y = y
        }
    }

    public struct Shadow {
        public static let small   = ShadowSpec(x: 4,  y: 4)   // 4 × 4
        public static let medium  = ShadowSpec(x: 6,  y: 6)   // 6 × 6
        public static let large   = ShadowSpec(x: 8,  y: 8)   // 8 × 8
        public static let massive = ShadowSpec(x: 12, y: 12)  // 12 × 12
        public static let lifted  = ShadowSpec(x: 10, y: 10)  // card hover state
    }

    // MARK: Motion — Mechanical, fast, linear. No ease-in-out. No bouncing springs.
    public struct Motion {
        /// Button press: 80ms hard snap
        public static let snap      = Animation.linear(duration: 0.08)
        /// Micro-interactions: 120ms linear
        public static let snappy    = Animation.linear(duration: 0.12)
        /// Hover & card lift: 150ms ease-out
        public static let spring    = Animation.easeOut(duration: 0.15)
        /// Layout / opacity shifts: 200ms ease-out
        public static let smooth    = Animation.easeOut(duration: 0.20)
        /// Card list entrance: 180ms ease-out
        public static let cardEnter = Animation.easeOut(duration: 0.18)
    }
}

// MARK: - View Extensions

public extension View {

    /// Neo-brutalist card: white fill · 4px black border · hard offset shadow.
    /// Elevated (hover) state: shadow grows from 6×6 to 10×10.
    func forgeGlassCard(isElevated: Bool = false) -> some View {
        let s = isElevated ? ForgeMediaTokens.Shadow.lifted : ForgeMediaTokens.Shadow.medium
        return self
            .background(Color.white)
            .clipShape(Rectangle())
            .overlay(Rectangle().stroke(Color.black, lineWidth: 4))
            .shadow(color: s.color, radius: s.radius, x: s.x, y: s.y)
    }

    /// Neo primary button: accent red fill · ink border · 4×4 hard shadow.
    func forgePrimaryButton() -> some View {
        self
            .font(.system(.subheadline, design: .default).weight(.bold))
            .foregroundColor(.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(ForgeMediaTokens.Colors.accent)
            .clipShape(Rectangle())
            .overlay(Rectangle().stroke(Color.black, lineWidth: 4))
            .shadow(color: .black, radius: 0, x: 4, y: 4)
    }

    /// Applies a ShadowSpec directly as a view modifier.
    func forgeHardShadow(_ spec: ForgeMediaTokens.ShadowSpec) -> some View {
        shadow(color: spec.color, radius: spec.radius, x: spec.x, y: spec.y)
    }

    /// Overlays a subtle grid paper texture on any background.
    func forgeGridTexture(cellSize: CGFloat = 28, opacity: Double = 0.07) -> some View {
        overlay(GridPatternView(cellSize: cellSize, lineOpacity: opacity))
    }

    /// Overlays a halftone dot pattern on any background.
    func forgeHalftoneTexture(dotSize: CGFloat = 1.5, spacing: CGFloat = 18, opacity: Double = 0.07) -> some View {
        overlay(HalftonePatternView(dotSize: dotSize, spacing: spacing, dotOpacity: opacity))
    }
}

// MARK: - Neo-Brutalist Button Style

/// Mechanical push-down button. Translates into its own shadow on press —
/// like a physical switch clicking down.
public struct NeoBrutalButtonStyle: ButtonStyle {
    public enum Variant {
        case primary    // Hot red background
        case secondary  // Vivid yellow background
        case outline    // White background
        case ghost      // Cream background
    }

    private let bgColor: Color
    private let textColor: Color
    private let shadowColor: Color

    public init(_ variant: Variant = .outline) {
        switch variant {
        case .primary:
            bgColor = ForgeMediaTokens.Colors.accent; textColor = .black; shadowColor = .black
        case .secondary:
            bgColor = ForgeMediaTokens.Colors.secondary; textColor = .black; shadowColor = .black
        case .outline:
            bgColor = .white; textColor = .black; shadowColor = .black
        case .ghost:
            bgColor = ForgeMediaTokens.Colors.canvas; textColor = .black; shadowColor = .black
        }
    }

    public init(bgColor: Color, textColor: Color = .black) {
        self.bgColor = bgColor
        self.textColor = textColor
        self.shadowColor = .black
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .default).weight(.bold))
            .foregroundColor(textColor)
            .lineLimit(1)
            .frame(height: 34)
            .padding(.horizontal, 14)
            .background(configuration.isPressed ? bgColor.opacity(0.85) : bgColor)
            .clipShape(Rectangle())
            .overlay(Rectangle().stroke(Color.black, lineWidth: 4))
            // Push-down effect: translates to cover its own shadow
            .offset(x: configuration.isPressed ? 3 : 0,
                    y: configuration.isPressed ? 3 : 0)
            .shadow(
                color: shadowColor, radius: 0,
                x: configuration.isPressed ? 0 : 4,
                y: configuration.isPressed ? 0 : 4
            )
            .animation(.linear(duration: 0.08), value: configuration.isPressed)
    }
}

// MARK: - Texture Background Views

/// Draws a repeating grid of light lines — graph-paper texture.
/// Used via `.forgeGridTexture()` or directly in a ZStack background.
public struct GridPatternView: View {
    let cellSize: CGFloat
    let lineOpacity: Double

    public init(cellSize: CGFloat = 28, lineOpacity: Double = 0.07) {
        self.cellSize = cellSize
        self.lineOpacity = lineOpacity
    }

    public var body: some View {
        Canvas { context, size in
            let shading = GraphicsContext.Shading.color(.black.opacity(lineOpacity))
            var x: CGFloat = 0
            while x <= size.width {
                var p = Path()
                p.move(to: CGPoint(x: x, y: 0))
                p.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(p, with: shading, lineWidth: 0.5)
                x += cellSize
            }
            var y: CGFloat = 0
            while y <= size.height {
                var p = Path()
                p.move(to: CGPoint(x: 0, y: y))
                p.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(p, with: shading, lineWidth: 0.5)
                y += cellSize
            }
        }
        .allowsHitTesting(false)
    }
}

/// Draws a regular grid of filled dots — halftone texture.
/// Used via `.forgeHalftoneTexture()` or directly in a ZStack background.
public struct HalftonePatternView: View {
    let dotSize: CGFloat
    let spacing: CGFloat
    let dotOpacity: Double

    public init(dotSize: CGFloat = 1.5, spacing: CGFloat = 18, dotOpacity: Double = 0.07) {
        self.dotSize = dotSize
        self.spacing = spacing
        self.dotOpacity = dotOpacity
    }

    public var body: some View {
        Canvas { context, size in
            let shading = GraphicsContext.Shading.color(.black.opacity(dotOpacity))
            var row: CGFloat = spacing / 2
            while row < size.height {
                var col: CGFloat = spacing / 2
                while col < size.width {
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: col - dotSize / 2, y: row - dotSize / 2,
                            width: dotSize, height: dotSize
                        )),
                        with: shading
                    )
                    col += spacing
                }
                row += spacing
            }
        }
        .allowsHitTesting(false)
    }
}
