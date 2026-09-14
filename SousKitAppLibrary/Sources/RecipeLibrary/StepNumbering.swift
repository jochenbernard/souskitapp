import SousKit

/// Step numbers as a cook reads them, counting on across the groups of a recipe.
public enum StepNumbering {
    /// A recipe's groups in order, each carrying the number its first step takes.
    ///
    /// The count runs on across the groups, so the numbering never restarts part way down a
    /// recipe.
    ///
    /// - Parameter recipe: The recipe to number.
    /// - Returns: The groups, in document order.
    public static func numberedGroups(of recipe: Recipe) -> [NumberedGroup] {
        var firstNumber = 1

        return recipe.groups.enumerated().map { index, group in
            defer { firstNumber += group.steps.count }

            return NumberedGroup(
                id: index,
                group: group,
                firstNumber: firstNumber
            )
        }
    }
}
