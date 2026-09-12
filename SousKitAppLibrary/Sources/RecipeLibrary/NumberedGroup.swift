import SousKit

/// One group of a recipe, with the number its first step takes.
public struct NumberedGroup: Identifiable {
    /// Where the group sits among the recipe's groups, which no two groups share.
    public let id: Int

    /// The group itself.
    public let group: StepGroup

    /// The number of the group's first step, counting from one across the whole recipe.
    public let firstNumber: Int
}
