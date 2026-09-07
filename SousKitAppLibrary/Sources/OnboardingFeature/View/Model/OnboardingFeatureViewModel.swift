import Observation

@Observable
@MainActor
final class OnboardingFeatureViewModel {
    var isChoosingDirectory = false
    var failureMessage: String?

    nonisolated init() {}
}
