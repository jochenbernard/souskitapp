/// One recipe as a repository lists it, before its contents are read.
public struct RecipeEntry: Sendable, Hashable, Identifiable {
    /// What the repository finds the recipe by, which no two of its recipes share.
    public let id: String

    /// The recipe's name, as a list shows it.
    public let name: String

    /// Whether the recipe's contents are on the device.
    public let availability: RecipeAvailability

    /// Creates an entry.
    ///
    /// - Parameters:
    ///   - id: What the repository finds the recipe by.
    ///   - name: The recipe's name, as a list shows it.
    ///   - availability: Whether the recipe's contents are on the device.
    public init(
        id: String,
        name: String,
        availability: RecipeAvailability
    ) {
        self.id = id
        self.name = name
        self.availability = availability
    }
}
