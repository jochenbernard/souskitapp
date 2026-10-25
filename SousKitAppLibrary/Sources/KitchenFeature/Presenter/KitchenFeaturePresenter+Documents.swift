import RecipeLibrary

extension KitchenFeaturePresenter {
    @MainActor
    func didOpen(_ document: RecipeDocument) {
        // Cooking is only ever left through its own exit.
        guard viewModel.openCooking == nil else {
            return
        }

        documentRequest.document = document

        // The file takes the place of what a cold start was opening again.
        if viewModel.isRestoring, !viewModel.isPushingRestoredRecipe {
            restorationKeeper.screensToRestore = []
            endRestoring()
        }

        openRequestedDocument()
    }

    /// Pushes the recipe in the file asked to be opened, once the kitchen's own screen has appeared and, for a file the
    /// repository holds, once the recipes are listed. A file the listing leaves out opens where it sits.
    @MainActor
    func openRequestedDocument() {
        guard
            let document = documentRequest.document,
            restorationKeeper.hasTopScreenAppeared,
            viewModel.openCooking == nil
        else {
            return
        }

        let screen: KitchenScreen

        if let recipeID = recipeRepository.recipeID(forFileAt: document.url) {
            guard let recipeEntries = documentRequest.recipeEntries else {
                return
            }

            let listedEntry = recipeEntries.first(where: { $0.id == recipeID })
            screen = listedEntry.map(KitchenScreen.recipe) ?? .document(document.entry)
        } else {
            screen = .document(document.entry)
        }

        documentRequest.document = nil

        // The recipe already on top stays as it is, read and scaled.
        guard viewModel.pushedScreens != [screen] else {
            return
        }

        switch screen {
        case .recipe(let recipeEntry):
            // No card under it to zoom out of, or back into.
            viewModel.zoomedRecipeIDs.remove(recipeEntry.id)
            changePushedScreens(to: [screen])

        case .document(let recipeEntry):
            changePushedScreens(to: [screen])
            viewModel.openRecipe = makeOpenRecipe(recipeEntry, reading: document.recipeRepository)

        case .folder:
            break
        }
    }
}
