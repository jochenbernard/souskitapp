/// One recipe as a repository lists it.
public struct RecipeEntry: Sendable, Hashable, Identifiable {
    /// What the repository finds the recipe by, which no two of its recipes share.
    public let id: String

    /// The recipe's name where its header gives no title, such as the name of the file holding it.
    public let name: String

    /// Whether the recipe's contents are on the device.
    public let availability: RecipeAvailability

    /// What the repository knows of the recipe's contents, or `nil` where it has not read them.
    public let summary: RecipeSummary?

    /// The names of the folders holding the recipe, from the outermost down, or none where it sits at the top.
    public let folderPath: [String]

    /// The picture the recipe's header names, or `nil` where it names none the repository holds.
    public let picture: RecipePicture?

    /// Creates an entry.
    ///
    /// - Parameters:
    ///   - id: What the repository finds the recipe by.
    ///   - name: The recipe's name where its header gives no title.
    ///   - availability: Whether the recipe's contents are on the device.
    ///   - summary: What the repository knows of the recipe's contents, or `nil` where it has not read them.
    ///   - folderPath: The names of the folders holding the recipe, from the outermost down.
    ///   - picture: The picture the recipe's header names, or `nil` where it names none the repository holds.
    public init(
        id: String,
        name: String,
        availability: RecipeAvailability,
        summary: RecipeSummary? = nil,
        folderPath: [String] = [],
        picture: RecipePicture? = nil
    ) {
        self.id = id
        self.name = name
        self.availability = availability
        self.summary = summary
        self.folderPath = folderPath
        self.picture = picture
    }
}
