/// What ``RecipeFeatureView`` reports to.
protocol RecipeFeaturePresenterProtocol {
    /// The view is on screen, and the call is cancelled when it leaves.
    @MainActor
    func viewDidAppear() async

    /// A section heading was tapped, which opens the section or closes it.
    @MainActor
    func didToggleSection(_ section: RecipeSection)
}
