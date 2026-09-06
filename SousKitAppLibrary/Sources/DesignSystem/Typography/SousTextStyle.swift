import SwiftUI

/// One entry in the type scale: a face per color scheme, a size, a line height, and tracking.
///
/// Sizes and line heights hold across themes; only the mono faces change. Values are given at
/// the default Dynamic Type size and scale against ``textStyle``, holding their ratios.
public struct SousTextStyle: Sendable, Hashable {
    /// 72/68 in Archivo SemiBold, set with negative leading.
    public static let display = SousTextStyle(
        face: .archivoSemiBold,
        size: 72.0,
        lineHeight: 68.0,
        textStyle: .largeTitle
    )

    /// 44/52 in Archivo Medium.
    public static let title = SousTextStyle(
        face: .archivoMedium,
        size: 44.0,
        lineHeight: 52.0,
        textStyle: .title
    )

    /// 24/32 in Archivo Medium.
    public static let heading = SousTextStyle(
        face: .archivoMedium,
        size: 24.0,
        lineHeight: 32.0,
        textStyle: .title3
    )

    /// 17/27 in Archivo Regular.
    ///
    /// Prose at this length steps one down from ``SousColor/text``, to
    /// ``SousPalette/graphite`` on light and ``SousPalette/chalk`` on dark.
    public static let body = SousTextStyle(
        face: .archivoRegular,
        size: 17.0,
        lineHeight: 27.0,
        textStyle: .body
    )

    /// 14/22 in JetBrains Mono, Medium on light and Regular on dark.
    ///
    /// For quantities, temperatures, times, and metadata.
    public static let data = SousTextStyle(
        face: .jetBrainsMonoMedium,
        size: 14.0,
        lineHeight: 22.0,
        textStyle: .subheadline,
        darkFace: .jetBrainsMonoRegular
    )

    /// 11/16 tracked 0.14em in JetBrains Mono, Medium on light and Regular on dark.
    ///
    /// For the label above a section.
    public static let eyebrow = SousTextStyle(
        face: .jetBrainsMonoMedium,
        size: 11.0,
        lineHeight: 16.0,
        textStyle: .caption2,
        darkFace: .jetBrainsMonoRegular,
        tracking: 11.0 * 0.14
    )

    /// Point size at the default Dynamic Type size.
    public let size: CGFloat

    /// Target line height in points, which may sit above or below the face's own.
    public let lineHeight: CGFloat

    /// The system text style this entry scales against.
    public let textStyle: Font.TextStyle

    /// Letter spacing in points at the default Dynamic Type size.
    public let tracking: CGFloat

    private let lightFace: SousFontFace
    private let darkFace: SousFontFace

    /// Creates an entry, for extending the scale beyond the six brand styles.
    ///
    /// - Parameters:
    ///   - face: The face to set in on a light color scheme.
    ///   - size: Point size at the default Dynamic Type size.
    ///   - lineHeight: Target line height in points.
    ///   - textStyle: The system text style to scale against.
    ///   - darkFace: The face to set in on a dark color scheme, defaulting to `face`.
    ///   - tracking: Letter spacing in points.
    public init(
        face: SousFontFace,
        size: CGFloat,
        lineHeight: CGFloat,
        textStyle: Font.TextStyle,
        darkFace: SousFontFace? = nil,
        tracking: CGFloat = 0.0
    ) {
        self.lightFace = face
        self.darkFace = darkFace ?? face
        self.size = size
        self.lineHeight = lineHeight
        self.textStyle = textStyle
        self.tracking = tracking
    }

    /// The face this entry is set in under a given scheme.
    ///
    /// - Parameter scheme: The scheme to resolve against.
    /// - Returns: The face for that scheme.
    public func face(in scheme: ColorScheme) -> SousFontFace {
        scheme == .dark ? darkFace : lightFace
    }
}
