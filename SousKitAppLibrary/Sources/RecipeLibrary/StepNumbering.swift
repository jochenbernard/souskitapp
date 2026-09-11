import SousKit

/// Step numbers as a cook reads them, counting on across the groups of a recipe.
public enum StepNumbering {
    /// The number the first step of a group takes, counting from the top of the recipe.
    ///
    /// - Parameters:
    ///   - index: Where the group sits among the recipe's groups.
    ///   - recipe: The recipe holding the group.
    /// - Returns: The number, counting from one.
    public static func firstNumber(ofGroupAt index: Int, in recipe: Recipe) -> Int {
        recipe.groups.prefix(index).reduce(1, { $0 + $1.steps.count })
    }
}
