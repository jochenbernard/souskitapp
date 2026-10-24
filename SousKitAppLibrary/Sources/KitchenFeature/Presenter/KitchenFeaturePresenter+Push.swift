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
    ///   - cardID: The card the screen zooms out of, where it is not the screen's own.
    /// - Returns: Whether the screen is on top of the stack now.
    @MainActor
    @discardableResult
    func push(
        _ screen: KitchenScreen,
        from origin: KitchenScreen?,
        zoomingOutOf cardID: KitchenCardID? = nil
    ) -> Bool {
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

        viewModel.zoomSources[screen.cardID] = cardID ?? screen.cardID
        changePushedScreens(to: pushedScreens)

        return viewModel.pushedScreens.last == screen
    }
}
