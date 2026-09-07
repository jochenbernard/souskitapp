import KitchenFeature
import OnboardingFeature

/// The one screen the app is on.
enum AppScreen {
    case onboarding(OnboardingFeature)
    case kitchen(KitchenFeature)

    /// Which case this is, for a transition to animate against.
    var isOnboarding: Bool {
        switch self {
        case .onboarding: true
        case .kitchen: false
        }
    }
}
