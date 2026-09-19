/// A recipe's header, sorted into what the recipe screen shows it as.
struct MetadataDisplay {
    /// The facts the header holds, in the order of ``MetadataFact/Kind``.
    let facts: [MetadataFact]

    /// The tags, from every `tags` line.
    let tags: [String]

    /// The allergens, read as a list.
    let allergens: [String]

    /// Every other header line, with the title left out.
    let rows: [MetadataRow]

    /// Whether there is nothing to show.
    var isEmpty: Bool {
        facts.isEmpty && tags.isEmpty && allergens.isEmpty && rows.isEmpty
    }
}
