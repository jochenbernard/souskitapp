@testable import CookingFeature

/// Records what the cooking feature sets the idle timer to.
@MainActor
final class IdleTimerSpy: IdleTimer {
    private(set) var settings: [Bool] = []

    func setDisabled(_ isDisabled: Bool) {
        settings.append(isDisabled)
    }
}
