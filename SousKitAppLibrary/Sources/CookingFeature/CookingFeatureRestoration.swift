/// What a cooking screen has done, kept so a cold start opens the screen as it was left.
public struct CookingFeatureRestoration: Sendable, Hashable, Codable {
    /// The numbers of the steps a cook ticked off.
    let completedStepNumbers: Set<Int>

    /// What the new timer sheet holds, or `nil` while it is closed.
    let newTimer: NewTimerEntry?

    /// Creates the restoration of cooking just opened, with no step done.
    public init() {
        self.init(completedStepNumbers: [])
    }

    init(completedStepNumbers: Set<Int>, newTimer: NewTimerEntry? = nil) {
        self.completedStepNumbers = completedStepNumbers
        self.newTimer = newTimer
    }
}
