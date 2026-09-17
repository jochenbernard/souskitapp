import CoreGraphics

/// The spacing scale, in points.
public enum SousSpacing {
    /// 2pt, the finest step.
    public static let hairline: CGFloat = 2.0

    /// 4pt, the smallest step.
    public static let xSmall: CGFloat = 4.0

    /// 8pt, for a label and its value.
    public static let small: CGFloat = 8.0

    /// 12pt, for related rows.
    public static let medium: CGFloat = 12.0

    /// 16pt, the default padding inside a surface.
    public static let large: CGFloat = 16.0

    /// 24pt, between groups within a section.
    public static let xLarge: CGFloat = 24.0

    /// 32pt, between sections.
    public static let xxLarge: CGFloat = 32.0

    /// 48pt, around a section on a page.
    public static let section: CGFloat = 48.0

    /// 64pt, for page margins on wide layouts.
    public static let page: CGFloat = 64.0
}
