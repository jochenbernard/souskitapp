struct CookingFeaturePresenterStub: CookingFeaturePresenterProtocol {
    func viewDidAppear() {}

    func viewDidDisappear() {}

    func didTapExit() {}

    func didChangeIsConfirmingExit(_: Bool) {}

    func didConfirmExit() {}
}
