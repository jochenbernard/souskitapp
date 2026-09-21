/// Where the app reads recipes from.
public enum RecipeRepositoryKind: Sendable, Hashable {
    /// The recipe files in the folder the user picked.
    case files

    /// Recipes kept in the app, for trying it where no folder can be picked, such as on a simulator.
    case mock
}
