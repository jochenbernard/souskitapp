import DesignSystem
import Foundation

/// Picks the color a recipe without a picture is drawn in from its title.
///
/// The hash is FNV-1a rather than `Hasher`, whose seed changes with every launch, and it reads the title rather than
/// the file, so a recipe keeps its color across launches, folders, and devices.
enum PlaceholderColorPick {
    private static let offsetBasis: UInt64 = 0xCBF2_9CE4_8422_2325
    private static let prime: UInt64 = 0x0000_0100_0000_01B3

    /// The color for a title, the same for titles differing only in case, accents, or spacing.
    ///
    /// - Parameter title: The title the recipe shows.
    /// - Returns: The color.
    static func color(forTitle title: String) -> SousPlaceholderColor {
        let colors = SousPlaceholderColor.allCases
        let index = Int(fnv1a(normalized(title)) % UInt64(colors.count))

        return colors[index]
    }

    /// The 64-bit FNV-1a hash of a text's UTF-8 bytes.
    ///
    /// - Parameter text: The text.
    /// - Returns: The hash.
    static func fnv1a(_ text: String) -> UInt64 {
        text.utf8.reduce(offsetBasis) { hash, byte in
            (hash ^ UInt64(byte)) &* prime
        }
    }

    private static func normalized(_ title: String) -> String {
        title
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
}
