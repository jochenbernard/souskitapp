import RecipeLibrary
import RecipeScaling

extension ScaleDisplay {
    /// What the sheet shows for the scale recipes open on, with the field holding what the user has typed.
    ///
    /// - Parameters:
    ///   - preferred: The scale recipes open on.
    ///   - text: What the field holds.
    init(preferred: RecipeScale, text: String) {
        self.init(
            target: preferred.target,
            text: text,
            targets: [.servings, .multiplier],
            // Servings and a multiple come to nothing on each other without a recipe to count them on.
            follows: [],
            isDefault: preferred == RecipeScale(.asWritten)
        )
    }
}
