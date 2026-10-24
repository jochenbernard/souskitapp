import RecipeLibrary

extension KitchenFeaturePresenter {
    @MainActor
    func didPush(_ screen: KitchenScreen, from origin: KitchenScreen?) {
        push(screen, from: origin)
    }

    /// Pushes a screen over the one a row was pressed on, which pops anything above that one.
    ///
    /// - Parameters:
    ///   - screen: The screen the row pushes.
    ///   - origin: The screen the row is on, or `nil` for the kitchen's own.
    /// - Returns: Whether the screen is on top of the stack now.
    @MainActor
    @discardableResult
    func push(_ screen: KitchenScreen, from origin: KitchenScreen?) -> Bool {
        // A row pressed with the button that opened something over the kitchen pushes nothing under it.
        guard !handler.kitchenFeatureIsCovered else {
            return false
        }

        stopRestoring()

        let pushedScreens: [KitchenScreen]

        if let origin {
            // A row pressed on a screen already popping pushes nothing.
            guard let index = viewModel.pushedScreens.firstIndex(of: origin) else {
                return false
            }

            pushedScreens = Array(viewModel.pushedScreens.prefix(through: index)) + [screen]
        } else {
            pushedScreens = [screen]
        }

        switch screen {
        case .recipe(let recipeEntry):
            viewModel.zoomedRecipeIDs.insert(recipeEntry.id)

        case .folder:
            // A folder pushed over a search field still active hangs UIKit in its search bar's layout.
            endSearch(on: origin)
        }

        changePushedScreens(to: pushedScreens)

        return viewModel.pushedScreens.last == screen
    }

    /// Lets go of the search field of the folder screen a row was pressed on, or `nil` for the kitchen's own.
    @MainActor
    private func endSearch(on origin: KitchenScreen?) {
        switch origin {
        case .folder(let folderPath):
            didChangeIsSearchPresented(false, in: folderPath)

        case nil:
            didChangeIsSearchPresented(false, in: [])

        case .recipe:
            break
        }
    }
}
