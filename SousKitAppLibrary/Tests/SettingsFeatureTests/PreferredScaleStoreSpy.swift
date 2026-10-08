import RecipeLibrary

/// Keeps the scales remembered in memory.
@MainActor
final class PreferredScaleStoreSpy: PreferredScaleStore {
    private(set) var preferredScale: PreferredScale

    init(_ preferredScale: PreferredScale = .asWritten) {
        self.preferredScale = preferredScale
    }

    func remember(_ preferredScale: PreferredScale) {
        self.preferredScale = preferredScale
    }
}
