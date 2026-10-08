import RecipeLibrary
import RecipeScaling

/// Builds ``SettingsFeature`` with what it reads and writes.
public struct SettingsFeatureFactory: Sendable {
    private let appVersion: AppVersion
    private let preferredScaleStore: PreferredScaleStore
    private let recipeRepositoryStore: RecipeRepositoryStore

    /// Creates a factory.
    ///
    /// - Parameters:
    ///   - appVersion: The version of the app that is running.
    ///   - preferredScaleStore: Where the scale recipes open on is remembered.
    ///   - recipeRepositoryStore: Where a newly picked folder is recorded.
    public init(
        appVersion: AppVersion,
        preferredScaleStore: PreferredScaleStore,
        recipeRepositoryStore: RecipeRepositoryStore
    ) {
        self.appVersion = appVersion
        self.preferredScaleStore = preferredScaleStore
        self.recipeRepositoryStore = recipeRepositoryStore
    }

    /// Builds the feature.
    ///
    /// - Parameters:
    ///   - recipeRepositoryName: What the user knows the recipes read now by.
    ///   - recipeRepositoryKind: The kind of repository the recipes are read from now.
    ///   - handler: What the feature reports to.
    /// - Returns: The feature.
    @MainActor
    public func makeSettingsFeature(
        recipeRepositoryName: String,
        recipeRepositoryKind: RecipeRepositoryKind,
        handler: SettingsFeatureHandler
    ) -> SettingsFeature {
        let viewModel = SettingsFeatureViewModel(
            recipeRepositoryName: recipeRepositoryName,
            recipeRepositoryKind: recipeRepositoryKind,
            appVersion: appVersion,
            scale: RecipeScale(preferredScaleStore.preferredScale)
        )
        let presenter = SettingsFeaturePresenter(
            handler: handler,
            preferredScaleStore: preferredScaleStore,
            recipeRepositoryStore: recipeRepositoryStore,
            viewModel: viewModel
        )

        return SettingsFeature(
            presenter: presenter,
            viewModel: viewModel
        )
    }
}
