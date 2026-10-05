@testable import CookingFeature

extension StepTimer {
    /// The timer of step 3, for 15 minutes.
    static func stubbed() -> Self {
        Self(
            stepNumber: 3,
            text: "15 min",
            duration: .seconds(900)
        )
    }
}
