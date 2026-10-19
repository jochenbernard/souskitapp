import SousKit

extension Recipe {
    /// The names of the ingredients the recipe is made of, in the order it first calls for them, each once.
    ///
    /// What the recipe marks as not eaten, such as foil, is left out, as its cookware is.
    public var foodIngredientNames: [String] {
        var seen: Set<String> = []

        return ingredients.filter({ !$0.flags.isNonFood }).map(\.name).filter({ seen.insert($0).inserted })
    }
}
