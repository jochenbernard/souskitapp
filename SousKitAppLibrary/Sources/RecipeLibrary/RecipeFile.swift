import Foundation

/// One recipe, as a file sitting directly in the recipe directory.
public struct RecipeFile: Sendable, Hashable, Identifiable {
    /// The extension every recipe file carries.
    public static let pathExtension = "sous"

    /// Where the file sits on disk.
    public let url: URL

    /// Whether the file's contents are on the device.
    public let availability: RecipeFileAvailability

    /// The file's name on disk, extension included.
    public let fileName: String

    /// The file's name set for reading: no extension, separators as spaces, casing untouched.
    public let name: String

    /// Where the file sits on disk, which no two recipes in one directory share.
    public var id: URL {
        url
    }

    /// Creates a recipe file.
    ///
    /// - Parameters:
    ///   - url: Where the file sits on disk.
    ///   - availability: Whether the file's contents are on the device.
    public init(url: URL, availability: RecipeFileAvailability) {
        self.url = url
        self.availability = availability
        self.fileName = url.lastPathComponent
        self.name = Self.name(forFileNamed: url.lastPathComponent)
    }

    /// Reduces a file name to the name shown for it.
    private static func name(forFileNamed fileName: String) -> String {
        let stem = URL(filePath: fileName).deletingPathExtension().lastPathComponent
        let words = stem.split(whereSeparator: isSeparator)

        guard !words.isEmpty else {
            return stem
        }

        return words.joined(separator: " ")
    }

    /// Whether a character stands between two words of a file name.
    private static func isSeparator(_ character: Character) -> Bool {
        character == "-" || character == "_" || character.isWhitespace
    }
}
