import RecipeLibrary

/// Holds one scale for recipes to open on.
@MainActor
final class PreferredScaleStoreStub: PreferredScaleStore {
    private(set) var preferredScale: PreferredScale

    init(_ preferredScale: PreferredScale = .asWritten) {
        self.preferredScale = preferredScale
    }

    func remember(_ preferredScale: PreferredScale) {
        self.preferredScale = preferredScale
    }
}
