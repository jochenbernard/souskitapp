/// What ``ScaleSheet`` reports to.
public protocol ScaleSheetPresenterProtocol {
    /// The sheet opened or closed.
    ///
    /// - Parameter isScaling: Whether the sheet is open.
    @MainActor
    func didChangeIsScaling(_ isScaling: Bool)

    /// A cook typed into the field holding the number.
    ///
    /// - Parameter text: What the field holds, which is not a number until it is typed out.
    @MainActor
    func didChangeScaleText(_ text: String)

    /// A cook tapped the minus or the plus beside the number.
    ///
    /// - Parameter steps: How many steps to take, which is -1 for the minus and 1 for the plus.
    @MainActor
    func didStepScale(by steps: Double)

    /// A cook chose what the number counts.
    ///
    /// - Parameter target: The target to count by.
    @MainActor
    func didTapTarget(_ target: ScaleTarget)

    /// A cook asked for the scale to reset to, target and number both.
    @MainActor
    func didTapReset()
}
