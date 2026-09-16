struct RecipeFeaturePresenterStub: RecipeFeaturePresenterProtocol {
    func viewDidAppear() {}

    func didChangeIsExpanded(_: Bool, of _: RecipeSection) {}

    func didTapCook() {}
}
