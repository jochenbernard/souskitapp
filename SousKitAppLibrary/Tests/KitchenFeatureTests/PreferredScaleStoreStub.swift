import RecipeLibrary

/// Keeps the scale remembered in memory.
@MainActor
final class PreferredScaleStoreStub: PreferredScaleStore {
    private(set) var preferredScale = PreferredScale.asWritten

    func remember(_ preferredScale: PreferredScale) {
        self.preferredScale = preferredScale
    }
}
