import SwiftUI

/// A color a recipe without a picture of its own is drawn in, so recipes tell apart at a glance.
///
/// The one set of colors besides the accent that is not a system color. A recipe keeps its color from launch to
/// launch, so a case is never reordered or removed without deciding that every recipe may change color.
public enum SousPlaceholderColor: CaseIterable, Sendable {
    case tomato
    case saffron
    case olive
    case sage
    case herb
    case teal
    case ocean
    case plum
    case berry
    case cocoa
    case slate

    /// The color, for the appearance in force.
    public var color: Color {
        Color(uiColor: UIColor { traits in
            UIColor(Color(hex: traits.userInterfaceStyle == .dark ? hex.dark : hex.light))
        })
    }

    private var hex: (light: UInt32, dark: UInt32) {
        switch self {
        case .tomato: (0xC2433A, 0xD65A50)
        case .saffron: (0xB7800F, 0xCF9A2C)
        case .olive: (0x77802F, 0x939C45)
        case .sage: (0x5B8768, 0x76A383)
        case .herb: (0x2F7A4D, 0x449565)
        case .teal: (0x1F7B82, 0x34979F)
        case .ocean: (0x2F62A3, 0x4C80C2)
        case .plum: (0x76498F, 0x9265AB)
        case .berry: (0xAA3966, 0xC5537F)
        case .cocoa: (0x85573A, 0xA27252)
        case .slate: (0x58636F, 0x76828E)
        }
    }
}
