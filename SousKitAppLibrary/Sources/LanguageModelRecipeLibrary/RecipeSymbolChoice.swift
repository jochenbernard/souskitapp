import FoundationModels

/// The answer the on-device model gives when asked for a recipe's symbol: one of the symbols a card can show.
@Generable
struct RecipeSymbolChoice {
    // Food, drink, cooking and occasions; symbols for the app's own controls and for things that are not food stay out.
    static let symbols = [
        "fork.knife", "frying.pan", "oven", "stove", "cooktop", "microwave", "refrigerator", "cup.and.saucer",
        "cup.and.heat.waves", "mug", "wineglass", "waterbottle", "birthday.cake", "carrot", "leaf", "fish", "flame",
        "drop", "snowflake", "takeoutbag.and.cup.and.straw", "popcorn", "pizza.slice", "spoon.serving", "basket",
        "hare", "bird", "tree", "laurel.leading", "sun.max", "sunrise", "moon.stars", "party.popper",
        "globe.europe.africa", "heat.waves", "gift"
    ]

    @Guide(description: "The SF Symbol that best evokes the dish", .anyOf(symbols))
    var symbol: String
}
