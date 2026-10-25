import RecipeLibrary

extension KitchenFeaturePresenter {
    @MainActor
    func screenDidAppear(_ screen: KitchenScreen) {
        let screensToRestore = restorationKeeper.screensToRestore

        guard !screensToRestore.isEmpty, viewModel.pushedScreens.last == screen else {
            return
        }

        let count = viewModel.pushedScreens.count + 1

        guard count < screensToRestore.count else {
            restorationKeeper.screensToRestore = []
            finishRestoring(screensToRestore)
            return
        }

        viewModel.pushedScreens = Array(screensToRestore.prefix(count))
    }

    /// Opens what the kitchen was built to open again, as far down as its folders are still listed, and its recipe
    /// where every folder and the recipe still are. What is no longer listed is forgotten.
    ///
    /// - Parameters:
    ///   - folder: The top of the repository as it is listed now, or `nil` where it could not be read.
    ///   - recipeEntries: The recipes listed now, in every folder.
    @MainActor
    func restore(in folder: KitchenFolder?, holding recipeEntries: [RecipeEntry]) {
        guard viewModel.isRestoring, restorationKeeper.screensToRestore.isEmpty else {
            return
        }

        guard let restoration = restorationKeeper.restoration, let folder else {
            viewModel.isRestoring = false
            restorationKeeper.save(nil)
            return
        }

        let folderScreens = restoration.folderPath.indices
            .map({ Array(restoration.folderPath.prefix(through: $0)) })
            .prefix(while: { folder.folder(at: $0) != nil })
            .map(KitchenScreen.folder)
        // Anywhere below the folders, since a search opens a recipe of any folder over the top one.
        let recipeEntry = recipeEntries.first { listedEntry in
            listedEntry.id == restoration.recipeID && listedEntry.folderPath.starts(with: restoration.folderPath)
        }
        let pushedScreens = folderScreens + (recipeEntry.map({ [KitchenScreen.recipe($0)] }) ?? [])

        guard !pushedScreens.isEmpty else {
            viewModel.isRestoring = false
            restorationKeeper.save(nil)
            return
        }

        guard pushedScreens.count > 1 else {
            finishRestoring(pushedScreens)
            return
        }

        // One at a time: a screen pushed under another without ever appearing loses its large title once uncovered,
        // where it has a subtitle.
        restorationKeeper.screensToRestore = pushedScreens
        viewModel.pushedScreens = [pushedScreens[0]]
    }

    /// Pushes the last of what a cold start opens again, with the recipe on top where there is one.
    ///
    /// - Parameter pushedScreens: Every screen the stack holds once restored.
    @MainActor
    func finishRestoring(_ pushedScreens: [KitchenScreen]) {
        viewModel.isRestoring = false
        viewModel.pushedScreens = pushedScreens

        if case .recipe(let recipeEntry) = pushedScreens.last {
            viewModel.openRecipe = makeOpenRecipe(
                recipeEntry,
                restoration: restorationKeeper.restoration?.recipe,
                resumesCooking: restorationKeeper.restoration?.cooking != nil
            )
        } else {
            restorationKeeper.save(Self.restoration(of: pushedScreens))
        }

        handler.kitchenFeatureDidRestore()
    }

    /// Leaves a restoration still pushing its screens where it stands, once the cook moves on the stack themselves.
    @MainActor
    func stopRestoring() {
        guard !restorationKeeper.screensToRestore.isEmpty else {
            return
        }

        restorationKeeper.screensToRestore = []
        viewModel.isRestoring = false
        handler.kitchenFeatureDidRestore()
    }
}
