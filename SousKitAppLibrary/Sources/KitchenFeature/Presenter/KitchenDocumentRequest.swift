import RecipeLibrary

/// The recipe file asked to be opened, which waits for the kitchen's own screen and, for a file the repository holds,
/// for the recipes to be listed.
///
/// A class, so every copy of the presenter keeps the same one.
@MainActor
final class KitchenDocumentRequest {
    /// The file waiting to be opened, or `nil` where none is.
    var document: RecipeDocument?

    // The recipes listed last, in every folder, or `nil` before the repository is first read.
    // swiftlint:disable:next discouraged_optional_collection
    var recipeEntries: [RecipeEntry]?

    nonisolated init() {}
}
