/// What the scale sheet has on it.
public struct ScaleDisplay {
    /// What the number counts.
    public let target: ScaleTarget

    /// What the field holds, which is not a number until it is typed out.
    public let text: String

    /// The targets to choose between, which is empty where there is only one.
    public let targets: [ScaleTarget]

    /// The same amount, read on the other targets.
    public let follows: [RecipeScale]

    /// Whether the scale is the one to reset to, which leaves nothing to reset.
    public let isDefault: Bool

    /// Creates what the sheet shows.
    ///
    /// - Parameters:
    ///   - target: What the number counts.
    ///   - text: What the field holds.
    ///   - targets: The targets to choose between, which is empty where there is only one.
    ///   - follows: The same amount, read on the other targets.
    ///   - isDefault: Whether the scale is the one to reset to.
    public init(
        target: ScaleTarget,
        text: String,
        targets: [ScaleTarget],
        follows: [RecipeScale],
        isDefault: Bool
    ) {
        self.target = target
        self.text = text
        self.targets = targets
        self.follows = follows
        self.isDefault = isDefault
    }
}
