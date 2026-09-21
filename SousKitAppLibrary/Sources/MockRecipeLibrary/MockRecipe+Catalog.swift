import RecipeLibrary

extension MockRecipe {
    /// Every recipe the repository lists, ordered by name as a folder lists them.
    ///
    /// The ten examples of the specification sit among recipes that are empty, malformed, annotated in every way the
    /// format allows, or all ten examples in one.
    static let all: [MockRecipe] = [
        MockRecipe(id: "boeuf-bourguignon"),
        MockRecipe(
            id: """
            boeuf-bourguignon-bouillabaisse-brioche-crepes-croque-monsieur-gratin-dauphinois-madeleines-\
            moules-marinieres-quiche-lorraine-and-vinaigrette
            """
        ),
        MockRecipe(id: "bouillabaisse"),
        MockRecipe(id: "brioche"),
        MockRecipe(id: "crepes", availability: .notDownloaded),
        MockRecipe(id: "croque-monsieur"),
        MockRecipe(id: "empty"),
        MockRecipe(id: "gratin-dauphinois", availability: .downloading),
        MockRecipe(id: "header-only"),
        MockRecipe(id: "madeleines"),
        MockRecipe(id: "malformed"),
        MockRecipe(id: "moules-marinieres"),
        MockRecipe(id: "quiche-lorraine"),
        MockRecipe(id: "steps-only"),
        MockRecipe(
            id: "unreachable",
            availability: .notDownloaded,
            isUnreachable: true
        ),
        MockRecipe(id: "unterminated-header"),
        MockRecipe(id: "unusual-annotations"),
        MockRecipe(id: "vinaigrette")
    ]
}
