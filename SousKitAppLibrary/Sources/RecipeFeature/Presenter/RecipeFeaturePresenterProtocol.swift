/// What ``RecipeFeatureView`` reports to.
protocol RecipeFeaturePresenterProtocol {
    /// The view is on screen, and the call is cancelled when it leaves.
    @MainActor
    func viewDidAppear() async

    @MainActor
    func didToggleSection(_ section: RecipeSection)

    @MainActor
    func didTapCook()
}
