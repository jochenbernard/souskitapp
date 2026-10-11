import Foundation
import KitchenFeature
import OnboardingFeature

/// The one screen the app is on.
enum AppScreen {
    /// A screen told apart from the others, each kitchen by the one time it was built.
    enum Identity: Hashable {
        case onboarding
        case kitchen(UUID)
    }

    case onboarding(OnboardingFeature)

    /// The kitchen, beside an id of its own, which a kitchen built for another repository does not share.
    case kitchen(KitchenFeature, id: UUID)

    /// Which screen this is, for a transition to animate against.
    var identity: Identity {
        switch self {
        case .onboarding: .onboarding
        case .kitchen(_, let id): .kitchen(id)
        }
    }
}
