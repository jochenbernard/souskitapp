import SwiftUI

extension Color {
    /// The accent color, for what is live, the current step, and the one primary action per screen.
    ///
    /// Draw it from here rather than from `Color.accentColor` or `.tint`, which a package preview
    /// resolves to blue.
    public static let accent = Color(hex: 0xEA5202)

    /// The accent as a fill for a large area that holds content, such as a callout.
    public static let quaternaryAccentFill = accent.opacity(0.125)
}

extension ShapeStyle where Self == Color {
    /// The accent color. See ``Color/accent``.
    public static var accent: Color { .accent }

    /// The accent as a fill for a large area. See ``Color/quaternaryAccentFill``.
    public static var quaternaryAccentFill: Color { .quaternaryAccentFill }
}
