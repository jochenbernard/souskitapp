import RecipeLibrary

extension MockRecipe {
    #if DEBUG
    /// Every recipe the repository lists, ordered by name as a folder lists them.
    ///
    /// The ten examples of the specification sit among recipes that are empty, malformed, annotated in every way the
    /// format allows, or all ten examples in one.
    static let all: [MockRecipe] = [
        MockRecipe(id: "boeuf-bourguignon", text: MockRecipes.boeufBourguignon),
        MockRecipe(
            id: """
            boeuf-bourguignon-bouillabaisse-brioche-crepes-croque-monsieur-gratin-dauphinois-madeleines-\
            moules-marinieres-quiche-lorraine-and-vinaigrette
            """,
            text: MockRecipes.everyExample
        ),
        MockRecipe(id: "bouillabaisse", text: MockRecipes.bouillabaisse),
        MockRecipe(id: "brioche", text: MockRecipes.brioche),
        MockRecipe(
            id: "crepes",
            text: MockRecipes.crepes,
            availability: .notDownloaded
        ),
        MockRecipe(id: "croque-monsieur", text: MockRecipes.croqueMonsieur),
        MockRecipe(id: "empty", text: MockRecipes.empty),
        MockRecipe(
            id: "gratin-dauphinois",
            text: MockRecipes.gratinDauphinois,
            availability: .downloading
        ),
        MockRecipe(id: "header-only", text: MockRecipes.headerOnly),
        MockRecipe(id: "madeleines", text: MockRecipes.madeleines),
        MockRecipe(id: "malformed", text: MockRecipes.malformed),
        MockRecipe(id: "moules-marinieres", text: MockRecipes.moulesMarinieres),
        MockRecipe(id: "quiche-lorraine", text: MockRecipes.quicheLorraine),
        MockRecipe(id: "steps-only", text: MockRecipes.stepsOnly),
        MockRecipe(
            id: "unreachable",
            text: nil,
            availability: .notDownloaded
        ),
        MockRecipe(id: "unterminated-header", text: MockRecipes.unterminatedHeader),
        MockRecipe(id: "unusual-annotations", text: MockRecipes.unusualAnnotations),
        MockRecipe(id: "vinaigrette", text: MockRecipes.vinaigrette)
    ]
    #else
    /// No recipes: they are there for trying the app where no folder can be picked, which only a debug build offers.
    static let all: [MockRecipe] = []
    #endif
}
