import RecipeScaling

struct RecipeFeaturePresenterStub: RecipeFeaturePresenterProtocol {
    func viewDidAppear() {}

    func didChangeIsExpanded(_: Bool, of _: RecipeSection) {}

    func didTapScale() {}

    func didChangeIsScaling(_: Bool) {}

    func didChangeScaleText(_: String) {}

    func didStepScale(by _: Double) {}

    func didTapTarget(_: ScaleTarget) {}

    func didTapReset() {}

    func didTapCook() {}
}
