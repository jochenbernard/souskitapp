import SousKit

/// One group of a recipe, with the number its first step takes.
public struct NumberedGroup: Identifiable {
    /// Where the group sits among the recipe's groups, which no two groups share.
    public let id: Int

    /// The group itself.
    public let group: StepGroup

    /// The number of the group's first step, counting from one across the whole recipe.
    public let firstNumber: Int

    /// The group's steps in order, each beside its number.
    public var numberedSteps: [(number: Int, step: Step)] {
        group.steps.enumerated().map({ (number: firstNumber + $0.offset, step: $0.element) })
    }
}
