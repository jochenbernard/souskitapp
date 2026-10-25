/// A recipe onboarding shows as a kitchen card, before there are recipes of the reader's own to show.
struct OnboardingShowcaseRecipe: Identifiable {
    /// The recipes, from the left of the fan to the right.
    static let all = [
        OnboardingShowcaseRecipe(
            title: "Quiche Lorraine",
            totalTime: .seconds(80 * 60),
            pictureName: "quiche-lorraine"
        ),
        OnboardingShowcaseRecipe(
            title: "Crepes",
            totalTime: .seconds(35 * 60),
            pictureName: "crepes"
        ),
        OnboardingShowcaseRecipe(
            title: "Bouillabaisse",
            totalTime: .seconds(90 * 60),
            pictureName: "bouillabaisse"
        )
    ]

    let title: String

    /// How long the recipe takes, which its card says under the title.
    let totalTime: Duration

    /// The name of the recipe's picture in the target's asset catalog.
    let pictureName: String

    var id: String {
        title
    }
}
