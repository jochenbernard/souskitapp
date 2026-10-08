import RecipeLibrary

/// What the settings asked of the app, reported once the sheet has slid away rather than tearing it down mid-slide.
enum SettingsExit {
    case connectRecipeRepository(RecipeRepository)
    case selectRecipeRepositoryKind(RecipeRepositoryKind)
    case reset
}
