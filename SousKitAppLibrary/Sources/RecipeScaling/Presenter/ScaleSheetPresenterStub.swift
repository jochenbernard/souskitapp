struct ScaleSheetPresenterStub: ScaleSheetPresenterProtocol {
    func didChangeIsScaling(_: Bool) {}

    func didChangeScaleText(_: String) {}

    func didStepScale(by _: Double) {}

    func didTapTarget(_: ScaleTarget) {}

    func didTapReset() {}
}
