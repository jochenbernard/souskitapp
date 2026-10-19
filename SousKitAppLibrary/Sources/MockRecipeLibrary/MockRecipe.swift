import RecipeLibrary

/// One file in the folder ``MockRecipeRepository`` stands in for: what it holds, and where it starts out.
///
/// Most are recipes. The rest are what a folder holds beside them, which the repository leaves out as a folder's
/// listing does.
struct MockRecipe: Sendable {
    private static let recipeExtension = ".sous"

    /// Where the file sits inside the folder, extension included, which no two files share.
    let path: String

    /// What the file holds, or `nil` for the recipe whose fetch never lands and for the files that are not recipes.
    let text: String?

    /// Whether the file is on the device before anything reads it.
    let availability: RecipeAvailability

    /// What the repository finds the recipe by: where it sits, as a folder finds one.
    var id: String {
        path
    }

    /// The recipe's name, as a list shows it: the words of its file's name.
    var name: String {
        String(fileName.dropLast(Self.recipeExtension.count)).replacing("-", with: " ")
    }

    /// The names of the folders holding the file, from the outermost down.
    var folderPath: [String] {
        Array(components.dropLast())
    }

    /// Whether the repository lists the file: a recipe, in no hidden folder.
    var isListed: Bool {
        fileName.hasSuffix(Self.recipeExtension) && !components.contains(where: { $0.hasPrefix(".") })
    }

    private var components: [String] {
        path.split(separator: "/").map(String.init)
    }

    private var fileName: String {
        components.last ?? path
    }

    init(
        path: String,
        text: String?,
        availability: RecipeAvailability = .downloaded
    ) {
        self.path = path
        self.text = text
        self.availability = availability
    }
}
