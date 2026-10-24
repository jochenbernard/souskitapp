/// One choice in a card's menu beside opening what the card opens, which is the card's accessibility action too.
struct CardMenuItem {
    /// What the choice is called, in the language the screen is shown in.
    let title: String

    /// The symbol shown beside the title.
    let systemImage: String

    let action: @MainActor () -> Void
}
