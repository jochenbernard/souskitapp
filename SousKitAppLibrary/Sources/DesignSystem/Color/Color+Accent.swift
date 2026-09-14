import SwiftUI

extension Color {
    /// The accent color, for what is live, the current step, and the one primary action per screen.
    ///
    /// Draw it from here rather than from `Color.accentColor` or `.tint`, which a package preview
    /// resolves to blue. It matches `AccentColor` in the app's asset catalog, and carries black
    /// text, never white.
    public static let accent = Color(hex: 0xF1541C)

    /// The accent at 12.5% opacity, for filling a large area that holds content, such as a callout.
    public static let quaternaryAccentFill = accent.opacity(0.125)
}

extension ShapeStyle where Self == Color {
    /// The accent color. See ``Color/accent``.
    public static var accent: Color { .accent }

    /// The accent at 12.5% opacity. See ``Color/quaternaryAccentFill``.
    public static var quaternaryAccentFill: Color { .quaternaryAccentFill }
}
