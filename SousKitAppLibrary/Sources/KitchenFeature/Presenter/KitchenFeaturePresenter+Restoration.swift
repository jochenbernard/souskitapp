import RecipeLibrary

extension KitchenFeaturePresenter {
    @MainActor
    func screenDidAppear(_ screen: KitchenScreen?) {
        if let screen {
            performMenuRequest(on: screen)
        }

        guard viewModel.pushedScreens.last == screen else {
            return
        }

        guard !viewModel.isPushingRestoredRecipe else {
            viewModel.isPushingRestoredRecipe = false
            endRestoring()
            return
        }

        if screen == nil {
            restorationKeeper.hasTopScreenAppeared = true
        }

        guard !restorationKeeper.screensToRestore.isEmpty else {
            return
        }

        restoreNextScreen()
    }

    /// Opens what the kitchen was built to open again, as far down as its folders are still listed, and its recipe
    /// where every folder and the recipe still are. What is no longer listed is forgotten.
    ///
    /// - Parameters:
    ///   - folder: The top of the repository as it is listed now, or `nil` where it could not be read.
    ///   - recipeEntries: The recipes listed now, in every folder.
    @MainActor
    func restore(in folder: KitchenFolder?, holding recipeEntries: [RecipeEntry]) {
        guard
            viewModel.isRestoring,
            restorationKeeper.screensToRestore.isEmpty,
            !viewModel.isPushingRestoredRecipe
        else {
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

        // One at a time, each over a screen that has appeared: a screen pushed under another without ever appearing
        // loses its large title once uncovered, where it has a subtitle.
        restorationKeeper.screensToRestore = pushedScreens

        if restorationKeeper.hasTopScreenAppeared {
            restoreNextScreen()
        }
    }

    /// Pushes the next screen a cold start opens again, over the ones on the stack, or the last of them.
    @MainActor
    func restoreNextScreen() {
        let screensToRestore = restorationKeeper.screensToRestore
        let count = viewModel.pushedScreens.count + 1

        guard count < screensToRestore.count else {
            restorationKeeper.screensToRestore = []
            finishRestoring(screensToRestore)
            return
        }

        viewModel.pushedScreens = Array(screensToRestore.prefix(count))
    }

    /// Pushes the last of what a cold start opens again, with the recipe on top where there is one, whose appearance
    /// then ends the restoration.
    ///
    /// - Parameter pushedScreens: Every screen the stack holds once restored.
    @MainActor
    func finishRestoring(_ pushedScreens: [KitchenScreen]) {
        guard case .recipe(let recipeEntry) = pushedScreens.last else {
            viewModel.pushedScreens = pushedScreens
            restorationKeeper.save(Self.restoration(of: pushedScreens))
            endRestoring()
            return
        }

        // Animated under the cover: a recipe pushed without animation leaves the screen under it collapsed.
        viewModel.isPushingRestoredRecipe = true
        viewModel.pushedScreens = pushedScreens
        viewModel.openRecipe = makeOpenRecipe(
            recipeEntry,
            restoration: restorationKeeper.restoration?.recipe,
            resumesCooking: restorationKeeper.restoration?.cooking != nil
        )
    }

    /// Leaves a restoration still pushing its screens where it stands, once the cook moves on the stack themselves.
    @MainActor
    func stopRestoring() {
        guard !restorationKeeper.screensToRestore.isEmpty else {
            return
        }

        restorationKeeper.screensToRestore = []
        endRestoring()
    }

    @MainActor
    func endRestoring() {
        viewModel.isRestoring = false
        handler.kitchenFeatureDidRestore()
    }
}
