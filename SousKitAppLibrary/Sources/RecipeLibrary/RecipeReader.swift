import SousKit

/// Reads a recipe and parses it.
public struct RecipeReader: Sendable {
    private let parser = SousParser()

    private let recipeTextReader: RecipeTextReader

    /// Creates a reader.
    ///
    /// - Parameter recipeDirectory: The directory the recipes sit in.
    public init(recipeDirectory: RecipeDirectory) {
        self.recipeTextReader = RecipeTextReader(recipeDirectory: recipeDirectory)
    }

    /// Reads a recipe and parses what it holds.
    ///
    /// Parsing always lands, so a recipe comes back whatever the file holds, with what the parser
    /// found wrong beside it. Only reading the file throws.
    ///
    /// - Parameter recipeFile: The recipe to read.
    /// - Returns: The recipe, and the diagnostics from parsing it.
    /// - Throws: Whatever reading the file throws.
    public func readRecipe(of recipeFile: RecipeFile) throws -> Parsed<Recipe> {
        let text = try recipeTextReader.readText(of: recipeFile)

        return parser.parseRecipe(text)
    }
}
