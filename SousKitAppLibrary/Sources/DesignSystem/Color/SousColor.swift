import SwiftUI

/// A semantic color token, resolved against the current color scheme.
///
/// A `ShapeStyle`, accepted anywhere a style is.
public struct SousColor: ShapeStyle, Sendable, Hashable {
    /// The page ground: Paper on light, Char on dark.
    public static let background = SousColor(light: SousPalette.paper, dark: SousPalette.char)

    /// Cards, sheets, and menus: White on light, Pan on dark.
    public static let surface = SousColor(light: SousPalette.white, dark: SousPalette.pan)

    /// Every rule, divider, and border: Line on light, Seam on dark.
    public static let border = SousColor(light: SousPalette.line, dark: SousPalette.seam)

    /// Headings, UI labels, and body text: Ink on light, Paper on dark.
    ///
    /// Long-form prose steps one down from this, to ``SousPalette/graphite`` on light and
    /// ``SousPalette/chalk`` on dark.
    public static let text = SousColor(light: SousPalette.ink, dark: SousPalette.paper)

    /// Secondary text and captions: Steel on light, Ash on dark.
    public static let textMuted = SousColor(light: SousPalette.steel, dark: SousPalette.ash)

    /// What is live, the current step, and the one primary action per screen: Flame in both
    /// schemes.
    ///
    /// Text drawn over this takes Ink, never White.
    public static let accent = SousColor(light: SousPalette.flame, dark: SousPalette.flame)

    /// The accent set as text, for links and pressed controls: Ember on light, Flame on dark.
    public static let accentText = SousColor(light: SousPalette.ember, dark: SousPalette.flame)

    private let light: Color
    private let dark: Color

    /// The value this token takes in a given scheme, for the APIs that require a `Color`.
    ///
    /// - Parameter scheme: The scheme to resolve against.
    /// - Returns: The palette value for that scheme.
    public func color(in scheme: ColorScheme) -> Color {
        scheme == .dark ? dark : light
    }

    /// Resolves the token against the environment's color scheme.
    ///
    /// - Parameter environment: The environment being drawn in.
    /// - Returns: The resolved color.
    public func resolve(in environment: EnvironmentValues) -> Color.Resolved {
        color(in: environment.colorScheme).resolve(in: environment)
    }
}

extension ShapeStyle where Self == SousColor {
    /// Paper on light, Char on dark. See ``SousColor/background``.
    public static var sousBackground: SousColor { .background }

    /// White on light, Pan on dark. See ``SousColor/surface``.
    public static var sousSurface: SousColor { .surface }

    /// Line on light, Seam on dark. See ``SousColor/border``.
    public static var sousBorder: SousColor { .border }

    /// Ink on light, Paper on dark. See ``SousColor/text``.
    public static var sousText: SousColor { .text }

    /// Steel on light, Ash on dark. See ``SousColor/textMuted``.
    public static var sousTextMuted: SousColor { .textMuted }

    /// Flame in both schemes. See ``SousColor/accent``.
    public static var sousAccent: SousColor { .accent }

    /// Ember on light, Flame on dark. See ``SousColor/accentText``.
    public static var sousAccentText: SousColor { .accentText }
}
