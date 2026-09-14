import SwiftUI

extension Color {
    /// The accent color, for what is live, the current step, and the one primary action per screen.
    ///
    /// Defined as `oklch(0.58 0.18 40)`, which sRGB holds as `#CD4805`, or 0.80392, 0.28235, 0.01961.
    ///
    /// Draw it from here rather than from `Color.accentColor` or `.tint`, which a package preview
    /// resolves to blue. It matches `AccentColor` in the app's asset catalog, and carries white
    /// text.
    public static let accent = Color(hex: 0xCD4805)

    /// The accent at 12.5% opacity, for filling a large area that holds content, such as a callout.
    public static let quaternaryAccentFill = accent.opacity(0.125)
}

extension ShapeStyle where Self == Color {
    /// The accent color. See ``Color/accent``.
    public static var accent: Color { .accent }

    /// The accent at 12.5% opacity. See ``Color/quaternaryAccentFill``.
    public static var quaternaryAccentFill: Color { .quaternaryAccentFill }
}
