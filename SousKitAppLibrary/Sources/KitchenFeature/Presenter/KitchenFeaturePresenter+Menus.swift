import RecipeFeature
import RecipeLibrary

extension KitchenFeaturePresenter {
    @MainActor
    func didPreview(_ recipeEntry: RecipeEntry) {
        // A recipe previewed again keeps the feature that read it, which reads it again as the preview appears.
        guard viewModel.previewedRecipe?.recipeEntry != recipeEntry else {
            return
        }

        viewModel.previewedRecipe = makeOpenRecipe(recipeEntry)
    }

    @MainActor
    func didChooseCooking(_ recipeEntry: RecipeEntry, from origin: KitchenScreen?) {
        push(.recipe(recipeEntry), from: origin, then: .cooking)
    }

    @MainActor
    func didChooseScaling(_ recipeEntry: RecipeEntry, from origin: KitchenScreen?) {
        push(.recipe(recipeEntry), from: origin, then: .scaling)
    }

    @MainActor
    func didChooseSharing(_ recipeEntry: RecipeEntry) async {
        // A file that cannot be fetched or copied opens no sheet, as there is nothing to hand on.
        guard
            let url = try? await recipeRepository.exportRecipeFile(of: recipeEntry),
            !Task.isCancelled
        else {
            return
        }

        viewModel.sharedFile = SharedRecipeFile(recipeEntry: recipeEntry, url: url)
    }

    @MainActor
    func didDismissSharing() {
        viewModel.sharedFile = nil
    }

    @MainActor
    func didChooseFolder(of recipeEntry: RecipeEntry, from origin: KitchenScreen?) {
        push(.folder(recipeEntry.folderPath), from: origin)
    }

    @MainActor
    func didChooseSearch(inFolderAt folderPath: [String], from origin: KitchenScreen?) {
        push(.folder(folderPath), from: origin, then: .searching)
    }

    /// Does what a card's menu asked of a screen it pushed, now that the screen is on display.
    @MainActor
    func performMenuRequest(on screen: KitchenScreen) {
        guard let action = menuRequest.take(for: screen) else {
            return
        }

        switch (action, screen) {
        case (.cooking, .recipe(let recipeEntry)):
            openRecipe(recipeEntry)?.feature.startCooking()

        case (.scaling, .recipe(let recipeEntry)):
            openRecipe(recipeEntry)?.feature.showScale()

        case (.searching, .folder(let folderPath)):
            viewModel.presentedSearchPath = folderPath

        case (.cooking, .folder), (.scaling, .folder), (.searching, .recipe):
            break
        }
    }

    /// Pushes a screen, which does something once it is on display.
    @MainActor
    private func push(
        _ screen: KitchenScreen,
        from origin: KitchenScreen?,
        then action: KitchenMenuRequest.Action
    ) {
        if push(screen, from: origin) {
            menuRequest.keep(action, for: screen)
        }
    }

    /// The recipe on the stack, where it is the one given.
    @MainActor
    private func openRecipe(_ recipeEntry: RecipeEntry) -> OpenRecipe? {
        viewModel.openRecipe?.recipeEntry == recipeEntry ? viewModel.openRecipe : nil
    }
}
