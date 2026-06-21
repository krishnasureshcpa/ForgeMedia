import SwiftUI

// MARK: - ForgeMedia Design Tokens
//
// Apple-native light materials, restrained color, and critically damped motion
// aligned to the ForgeMedia Open Design hyperframes.

public struct ForgeMediaTokens {
    // MARK: Glass Tiers (Backdrop Filter Materials)
    public struct Glass {
        // Base: Window background
        public static let base = Material.ultraThinMaterial
        // Surface: Cards, default panels
        public static let surface = Material.thinMaterial
        // Elevated: Hover states, active cards
        public static let elevated = Material.regularMaterial
        // Floating: Modals, popovers, context menus
        public static let floating = Material.thickMaterial
    }

    // MARK: Colors
    public struct Colors {
        // Neutrals
        public static let bg = Color(red: 0.961, green: 0.961, blue: 0.969)         // #f5f5f7
        public static let fg = Color(red: 0.114, green: 0.114, blue: 0.122)          // #1d1d1f
        public static let fgSecondary = Color(red: 0.259, green: 0.259, blue: 0.271) // #424245
        public static let muted = Color(red: 0.431, green: 0.431, blue: 0.451)       // #6e6e73

        // Borders
        public static let borderSoft = Color(red: 0.910, green: 0.910, blue: 0.929).opacity(0.6)
        public static let border = Color.black.opacity(0.08)

        // Accents
        public static let accent = Color(red: 0.0, green: 0.4, blue: 0.8)            // #0066cc
        public static let accentStrong = Color(red: 0.0, green: 0.467, blue: 0.929)  // #0077ed
        public static let accentGlow = Color(red: 0.0, green: 0.4, blue: 0.8).opacity(0.12)

        public static let warning = Color(red: 0.831, green: 0.537, blue: 0.047)     // #d4890c
        public static let warningGlow = Color(red: 0.831, green: 0.537, blue: 0.047).opacity(0.12)

        public static let teal = Color(red: 0.039, green: 0.561, blue: 0.533)        // #0a8f88
        public static let tealGlow = Color(red: 0.039, green: 0.561, blue: 0.533).opacity(0.10)

        public static let success = Color(red: 0.102, green: 0.549, blue: 0.361)     // #1a8c5c
        public static let danger = Color(red: 0.831, green: 0.231, blue: 0.231)      // #d43b3b
        public static let dangerGlow = Color(red: 0.831, green: 0.231, blue: 0.231).opacity(0.10)
    }

    // MARK: Geometry (Squircle approximation via continuous)
    public struct Radii {
        public static let compact: CGFloat = 8
        public static let `default`: CGFloat = 12
        public static let large: CGFloat = 18
        public static let pill: CGFloat = 980 // True pill shape
    }

    // MARK: Motion (Critically Damped Springs & Smooth Easing)
    public struct Motion {
        // Spring for physical, tactile interactions (hover, press, drag)
        // Mimics Apple's default spring: response 0.5, dampingFraction 0.825
        public static let spring = Animation.spring(response: 0.35, dampingFraction: 0.7, blendDuration: 0)

        // Smooth easing for opacity, color, and progress fills (no bouncing)
        public static let smooth = Animation.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 0.4)

        // Fast, snappy easing for micro-interactions
        public static let snappy = Animation.timingCurve(0.25, 0.46, 0.45, 0.94, duration: 0.15)

        // Card enter/exit (slight overshoot for premium feel)
        public static let cardEnter = Animation.timingCurve(0.05, 0.7, 0.1, 1.0, duration: 0.28)
    }
}

// MARK: - View Extensions

public extension View {
    /// Applies ForgeMedia's compact glass card style with native edge definition.
    func forgeGlassCard(isElevated: Bool = false) -> some View {
        self
            .background(isElevated ? ForgeMediaTokens.Glass.elevated : ForgeMediaTokens.Glass.surface)
            .clipShape(RoundedRectangle(cornerRadius: ForgeMediaTokens.Radii.default, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: ForgeMediaTokens.Radii.default, style: .continuous)
                    .stroke(ForgeMediaTokens.Colors.border, lineWidth: 0.5)
            )
            .shadow(
                color: .black.opacity(isElevated ? 0.12 : 0.06),
                radius: isElevated ? 12 : 4,
                x: 0,
                y: isElevated ? 6 : 2
            )
    }

    /// Applies the primary action button style with tactile press feedback.
    func forgePrimaryButton() -> some View {
        self
            .font(.system(.body, design: .default).weight(.medium))
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(ForgeMediaTokens.Colors.accent)
            .clipShape(Capsule(style: .continuous))
            .shadow(color: ForgeMediaTokens.Colors.accent.opacity(0.3), radius: 4, x: 0, y: 2)
    }

    /// Adds a subtle ambient glow effect behind the view.
    func forgeAmbientGlow(color: Color, radius: CGFloat = 40) -> some View {
        self.overlay(
            Circle()
                .fill(color)
                .blur(radius: radius)
                .opacity(0.6)
                .offset(y: 4)
        )
    }
}
