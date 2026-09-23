import KitchenFeature
import OnboardingFeature
import RecipeLibrary

/// The one screen the app is on.
enum AppScreen {
    /// A screen told apart from the others, the kitchen by the kind of repository it reads.
    enum Identity: Hashable {
        case onboarding
        case kitchen(RecipeRepositoryKind)
    }

    case onboarding(OnboardingFeature)

    /// The kitchen, beside the kind of repository it reads.
    case kitchen(KitchenFeature, RecipeRepositoryKind)

    /// Which screen this is, for a transition to animate against.
    var identity: Identity {
        switch self {
        case .onboarding: .onboarding
        case .kitchen(_, let recipeRepositoryKind): .kitchen(recipeRepositoryKind)
        }
    }
}
