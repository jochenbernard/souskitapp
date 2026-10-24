/// The symbol inputs of the recipes listed last, each made again only where its recipe changed since.
struct RecipeSymbolInputs {
    private struct MadeInput {
        let name: String
        let summary: RecipeSummary
        let ingredientNames: [String]
        let input: RecipeSymbolInput
    }

    // By recipe id.
    private var madeInputs: [String: MadeInput] = [:]

    /// Keeps the inputs of the recipes, forgetting those of every other recipe.
    ///
    /// - Parameter listedRecipes: The recipes.
    mutating func keep(_ listedRecipes: [ListedRecipe]) {
        madeInputs = Dictionary(
            listedRecipes.compactMap { listedRecipe in
                guard
                    let summary = listedRecipe.entry.summary,
                    let input = input(for: listedRecipe)
                else {
                    return nil
                }

                let madeInput = MadeInput(
                    name: listedRecipe.entry.name,
                    summary: summary,
                    ingredientNames: listedRecipe.ingredientNames,
                    input: input
                )

                return (listedRecipe.entry.id, madeInput)
            },
            uniquingKeysWith: { $1 }
        )
    }

    /// The input of a recipe, kept where the recipe has not changed since.
    ///
    /// - Parameter listedRecipe: The recipe.
    /// - Returns: The input, or `nil` where the recipe's contents have not been read.
    func input(for listedRecipe: ListedRecipe) -> RecipeSymbolInput? {
        guard
            let madeInput = madeInputs[listedRecipe.entry.id],
            madeInput.name == listedRecipe.entry.name,
            madeInput.summary == listedRecipe.entry.summary,
            madeInput.ingredientNames == listedRecipe.ingredientNames
        else {
            return RecipeSymbolInput(listedRecipe: listedRecipe)
        }

        return madeInput.input
    }
}
