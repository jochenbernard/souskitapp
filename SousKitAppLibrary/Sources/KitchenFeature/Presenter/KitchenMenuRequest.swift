/// What a card's menu asked of the screen it pushed, which waits for the push to finish, so a sheet or a cover does
/// not open over a screen still sliding in.
///
/// A class, so every copy of the presenter keeps the same one.
@MainActor
final class KitchenMenuRequest {
    /// Something a pushed screen does once it is on display.
    enum Action {
        /// Starting cooking from a recipe, as its button does.
        case cooking

        /// Opening a recipe's scale sheet.
        case scaling

        /// Searching in a folder.
        case searching
    }

    private var kept: (screen: KitchenScreen, action: Action)?

    nonisolated init() {}

    /// Keeps an action for a screen to do once it is on display, in place of any kept before.
    func keep(_ action: Action, for screen: KitchenScreen) {
        kept = (screen, action)
    }

    /// Hands over the action kept for a screen, and forgets it.
    ///
    /// - Returns: The action, or `nil` where none is kept for the screen.
    func take(for screen: KitchenScreen) -> Action? {
        guard
            let kept,
            kept.screen == screen
        else {
            return nil
        }

        forget()

        return kept.action
    }

    /// Forgets the action kept, whatever screen it was for.
    func forget() {
        kept = nil
    }
}
