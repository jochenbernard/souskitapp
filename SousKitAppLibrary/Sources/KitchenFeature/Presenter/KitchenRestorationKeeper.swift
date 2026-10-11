/// What the kitchen has open now, reported as it changes.
///
/// A class, so every copy of the presenter changes the same one.
@MainActor
final class KitchenRestorationKeeper {
    private(set) var restoration: KitchenFeatureRestoration?

    private let handler: KitchenFeatureHandler

    /// Creates a keeper.
    ///
    /// - Parameters:
    ///   - restoration: What the kitchen is built to open again, or `nil` on its recipe list.
    ///   - handler: What the changes are reported to.
    init(
        restoration: KitchenFeatureRestoration?,
        handler: KitchenFeatureHandler
    ) {
        self.restoration = restoration
        self.handler = handler
    }

    /// Keeps what the kitchen has open.
    ///
    /// - Parameter restoration: What the kitchen has open, or `nil` on its recipe list with nothing over it.
    func save(_ restoration: KitchenFeatureRestoration?) {
        self.restoration = restoration
        handler.kitchenFeatureDidChangeRestoration(restoration)
    }

    /// Changes what the kitchen has open for a recipe, or leaves it as it is where another is open.
    ///
    /// - Parameters:
    ///   - recipeID: The id of the recipe the change is for.
    ///   - change: The change.
    func update(recipeID: String, _ change: (inout KitchenFeatureRestoration) -> Void) {
        guard
            var restoration,
            restoration.recipeID == recipeID
        else {
            return
        }

        change(&restoration)
        save(restoration)
    }
}
