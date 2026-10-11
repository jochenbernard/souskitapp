import RecipeScaling

/// What ``RecipeFeatureView`` reports to.
protocol RecipeFeaturePresenterProtocol: ScaleSheetPresenterProtocol {
    /// The view is on screen, and the call is cancelled when it leaves.
    @MainActor
    func viewDidAppear() async

    @MainActor
    func didChangeIsExpanded(_ isExpanded: Bool, of section: RecipeSection)

    @MainActor
    func didTapScale()

    @MainActor
    func didTapCook()
}
