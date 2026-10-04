import Foundation
import RecipeLibrary

/// Where the app reads recipes from, remembered across launches.
struct RecipeRepositoryKindStore {
    private static let key = "RecipeRepositoryKindStore.readsMockRecipes"

    private let userDefaults: UserDefaults

    /// The kind picked last, or the files in the folder before any was picked and in a release build.
    var recipeRepositoryKind: RecipeRepositoryKind {
        #if DEBUG
        userDefaults.bool(forKey: Self.key) ? .mock : .files
        #else
        // A release build offers no way back from the mock recipes a debug build left picked.
        .files
        #endif
    }

    /// Creates a store.
    ///
    /// - Parameter userDefaults: Where the kind is remembered.
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    /// Records a kind as the one recipes are read from.
    ///
    /// - Parameter recipeRepositoryKind: The kind picked.
    func remember(_ recipeRepositoryKind: RecipeRepositoryKind) {
        userDefaults.set(recipeRepositoryKind == .mock, forKey: Self.key)
    }

    /// Forgets the kind, leaving the app on the files in the folder.
    func clear() {
        userDefaults.removeObject(forKey: Self.key)
    }
}
