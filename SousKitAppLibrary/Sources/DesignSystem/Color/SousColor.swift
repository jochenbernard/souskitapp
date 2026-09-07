import SwiftUI

/// The semantic color tokens, each one reading the color scheme it is drawn in.
///
/// Every token is a `Color`, so it is accepted both where a style is and where a color is, and
/// a call site never branches on the scheme to reach a value.
public enum SousColor {
    /// The page ground: Paper on light, Char on dark.
    public static let background = Color(light: SousPalette.paper, dark: SousPalette.char)

    /// Cards, sheets, and menus: White on light, Pan on dark.
    public static let surface = Color(light: SousPalette.white, dark: SousPalette.pan)

    /// Every rule, divider, and border: Line on light, Seam on dark.
    public static let border = Color(light: SousPalette.line, dark: SousPalette.seam)

    /// Headings, UI labels, and body text: Ink on light, Paper on dark.
    ///
    /// Long-form prose steps one down from this, to ``SousPalette/graphite`` on light and
    /// ``SousPalette/chalk`` on dark.
    public static let text = Color(light: SousPalette.ink, dark: SousPalette.paper)

    /// Secondary text and captions: Steel on light, Ash on dark.
    public static let textMuted = Color(light: SousPalette.steel, dark: SousPalette.ash)

    /// What is live, the current step, and the one primary action per screen: Flame in both
    /// schemes.
    ///
    /// Text drawn over this takes Ink, never White.
    public static let accent = Color(light: SousPalette.flame, dark: SousPalette.flame)

    /// The accent set as text, for links and pressed controls: Ember on light, Flame on dark.
    public static let accentText = Color(light: SousPalette.ember, dark: SousPalette.flame)
}

extension ShapeStyle where Self == Color {
    /// Paper on light, Char on dark. See ``SousColor/background``.
    public static var sousBackground: Color { SousColor.background }

    /// White on light, Pan on dark. See ``SousColor/surface``.
    public static var sousSurface: Color { SousColor.surface }

    /// Line on light, Seam on dark. See ``SousColor/border``.
    public static var sousBorder: Color { SousColor.border }

    /// Ink on light, Paper on dark. See ``SousColor/text``.
    public static var sousText: Color { SousColor.text }

    /// Steel on light, Ash on dark. See ``SousColor/textMuted``.
    public static var sousTextMuted: Color { SousColor.textMuted }

    /// Flame in both schemes. See ``SousColor/accent``.
    public static var sousAccent: Color { SousColor.accent }

    /// Ember on light, Flame on dark. See ``SousColor/accentText``.
    public static var sousAccentText: Color { SousColor.accentText }
}
