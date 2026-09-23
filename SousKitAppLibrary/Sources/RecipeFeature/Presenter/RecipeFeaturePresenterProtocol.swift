/// What ``RecipeFeatureView`` reports to.
protocol RecipeFeaturePresenterProtocol {
    /// The view is on screen, and the call is cancelled when it leaves.
    @MainActor
    func viewDidAppear() async

    @MainActor
    func didChangeIsExpanded(_ isExpanded: Bool, of section: RecipeSection)

    @MainActor
    func didTapScale()

    @MainActor
    func didChangeIsScaling(_ isScaling: Bool)

    /// A cook typed into the field holding how much of the recipe to make.
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
    /// - Parameter target: The target to set the recipe by, which holds the amount where it is.
    @MainActor
    func didTapTarget(_ target: ScaleTarget)

    /// A cook asked for the scale the recipe opens on, target and number both.
    @MainActor
    func didTapReset()

    @MainActor
    func didTapCook()
}
