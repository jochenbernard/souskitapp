/// What was asked of the screen from outside it before its recipe was read, which the read then does.
///
/// A class, so every copy of the presenter keeps the same one.
@MainActor
final class RecipeRequestMemory {
    /// Something the screen does once its recipe is read.
    enum Request {
        /// Starting cooking, as the screen's button does.
        case cooking

        /// Opening the scale sheet.
        case scaling
    }

    /// What waits for the recipe, or `nil` where nothing does.
    var request: Request?

    nonisolated init() {}
}
