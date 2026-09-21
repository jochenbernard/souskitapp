/// What the scale sheet has on it.
struct ScaleDisplay {
    /// What the number counts.
    let target: ScaleTarget

    /// What the field holds, which is not a number until it is typed out.
    let text: String

    /// The targets to choose between, which is empty where the recipe declares only one.
    let targets: [ScaleTarget]

    /// The same amount of food, read on the recipe's other targets.
    let follows: [RecipeScale]

    /// Whether the recipe stands at the scale it opens on, which leaves nothing to reset.
    let isDefault: Bool

    /// What the sheet shows for a recipe, with the field holding what a cook has typed.
    ///
    /// - Parameters:
    ///   - recipe: The recipe at the scale in force.
    ///   - text: What the field holds.
    init(recipe: ScaledRecipe, text: String) {
        let declared = recipe.targets

        self.target = recipe.scale.target
        self.text = text
        // One target is no choice, so the chips are left off rather than offering it.
        self.targets = declared.count > 1 ? declared : []
        self.follows = declared
            .filter({ $0 != recipe.scale.target })
            .compactMap({ target in
                recipe.value(of: target).map({ RecipeScale(target: target, value: $0) })
            })
        self.isDefault = recipe.isDefault
    }
}
