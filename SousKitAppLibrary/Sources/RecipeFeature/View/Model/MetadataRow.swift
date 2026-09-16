import Foundation

/// One header line of a recipe, ready to show.
struct MetadataRow: Identifiable {
    /// Where the line sits in the header, which no two lines share.
    let id: Int

    /// The key, or empty for a line the header could not be read as `key: value`.
    let key: String

    /// What the line holds, with a list joined into one line.
    let value: String

    /// The key as a label, `prep-time` reading as "Prep time".
    var label: String {
        let words = key.replacingOccurrences(of: "-", with: " ")

        return words.prefix(1).uppercased() + words.dropFirst()
    }
}
