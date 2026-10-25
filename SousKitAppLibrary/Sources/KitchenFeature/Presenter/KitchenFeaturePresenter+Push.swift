extension KitchenFeaturePresenter {
    @MainActor
    func didPush(_ screen: KitchenScreen, from origin: KitchenScreen?) {
        // A row pressed with the button that opened something over the kitchen pushes nothing under it.
        guard !handler.kitchenFeatureIsCovered else {
            return
        }

        stopRestoring()

        let pushedScreens: [KitchenScreen]

        if let origin {
            // A row pressed on a screen already popping pushes nothing.
            guard let index = viewModel.pushedScreens.firstIndex(of: origin) else {
                return
            }

            pushedScreens = Array(viewModel.pushedScreens.prefix(through: index)) + [screen]
        } else {
            pushedScreens = [screen]
        }

        switch screen {
        case .recipe:
            break

        case .folder:
            // A folder pushed over a search field still active hangs UIKit in its search bar's layout.
            endSearch(on: origin)
        }

        changePushedScreens(to: pushedScreens)
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
