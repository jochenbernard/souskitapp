/// The scale recipes open on, remembered across launches.
public protocol PreferredScaleStore: Sendable {
    /// The scale picked last, or the amounts as written before any was picked.
    @MainActor
    var preferredScale: PreferredScale { get }

    /// Records a scale as the one recipes open on.
    ///
    /// - Parameter preferredScale: The scale picked.
    @MainActor
    func remember(_ preferredScale: PreferredScale)
}
