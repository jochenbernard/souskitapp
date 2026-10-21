import SwiftUI

/// A color a recipe without a picture of its own is drawn in, so recipes tell apart at a glance.
///
/// The one set of colors besides the accent that is not a system color, the same in light and dark. A recipe keeps
/// its color from launch to launch, so a case is never reordered or removed without deciding that every recipe may
/// change color.
public enum SousPlaceholderColor: CaseIterable, Sendable {
    case pink
    case orange
    case yellow
    case green
    case teal
    case blue
    case indigo
    case purple

    // The accent's lightness and half its chroma, which every hue holds inside sRGB.
    private static let lightness = 0.64
    private static let chroma = 0.10

    /// The color.
    public var color: Color {
        Color(
            oklchLightness: Self.lightness,
            chroma: Self.chroma,
            hue: hue
        )
    }

    // Every 45 degrees, half a step off the accent's 40, so none falls on the accent.
    private var hue: Double {
        switch self {
        case .pink: 17.5
        case .orange: 62.5
        case .yellow: 107.5
        case .green: 152.5
        case .teal: 197.5
        case .blue: 242.5
        case .indigo: 287.5
        case .purple: 332.5
        }
    }
}
