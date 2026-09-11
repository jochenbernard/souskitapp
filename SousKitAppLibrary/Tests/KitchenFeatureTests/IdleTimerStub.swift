import CookingFeature

/// An idle timer that leaves the screen as it is.
struct IdleTimerStub: IdleTimer {
    func setDisabled(_: Bool) {}
}
