/// What a cooking screen has done, kept so a cold start opens the screen as it was left.
public struct CookingFeatureRestoration: Sendable, Hashable, Codable {
    /// The numbers of the steps a cook ticked off.
    let completedStepNumbers: Set<Int>

    /// Creates the restoration of cooking just opened, with no step done.
    public init() {
        self.init(completedStepNumbers: [])
    }

    init(completedStepNumbers: Set<Int>) {
        self.completedStepNumbers = completedStepNumbers
    }
}
