import Foundation

/// One header line of a recipe, ready to show.
struct MetadataRow: Identifiable {
    /// Where the line sits in the header, which no two lines share.
    let id: Int

    /// The key, or empty for a line the header could not be read as `key: value`.
    let key: String

    /// What the line holds, with a list joined into one line.
    let value: String

    /// The key where the screen has a label for it, or `nil` where the file's own words stand.
    let knownKey: MetadataKey?

    /// The key as the file writes it, `prep-time` reading as "Prep time".
    let label: String

    init(
        id: Int,
        key: String,
        value: String
    ) {
        let words = key.replacingOccurrences(of: "-", with: " ")

        self.id = id
        self.key = key
        self.value = value
        self.knownKey = MetadataKey(key: key)
        self.label = words.prefix(1).uppercased() + words.dropFirst()
    }
}
