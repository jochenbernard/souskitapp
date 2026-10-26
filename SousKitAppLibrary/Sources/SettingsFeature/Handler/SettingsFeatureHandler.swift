import RecipeLibrary

/// What ``SettingsFeature`` reports to.
public protocol SettingsFeatureHandler {
    /// The user is done with the settings.
    @MainActor
    func settingsFeatureDidFinish()

    /// The user picked another folder, and it is recorded.
    ///
    /// - Parameter recipeRepository: The repository reading the folder.
    @MainActor
    func settingsFeatureDidConnectRecipeRepository(_ recipeRepository: RecipeRepository)

    /// Another kind of recipe repository was picked to read from, which a debug build offers.
    ///
    /// - Parameter recipeRepositoryKind: The kind picked.
    @MainActor
    func settingsFeatureDidSelectRecipeRepositoryKind(_ recipeRepositoryKind: RecipeRepositoryKind)

    /// A reset of the app was confirmed, which a debug build offers, and the app is to be as freshly installed.
    @MainActor
    func settingsFeatureDidConfirmReset()
}
