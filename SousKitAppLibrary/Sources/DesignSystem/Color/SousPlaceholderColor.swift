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

    /// The color.
    public var color: Color {
        Color(hex: hex)
    }

    // Picked in OKLCH around the accent and rounded to sRGB; the README's placeholder colors section shows how.
    private var hex: UInt32 {
        switch self {
        case .pink: 0xC17276 // oklch(0.64 0.10 17.5)
        case .orange: 0xB77E48 // oklch(0.64 0.10 62.5)
        case .yellow: 0x939043 // oklch(0.64 0.10 107.5)
        case .green: 0x599E6E // oklch(0.64 0.10 152.5)
        case .teal: 0x279EA1 // oklch(0.64 0.10 197.5)
        case .blue: 0x5193C4 // oklch(0.64 0.10 242.5)
        case .indigo: 0x8982C6 // oklch(0.64 0.10 287.5)
        case .purple: 0xB075A7 // oklch(0.64 0.10 332.5)
        }
    }
}
