struct KitchenFeaturePresenterStub: KitchenFeaturePresenterProtocol {
    func viewDidAppear() {}

    func didBecomeActive() {}

    func didChangeScreenPath(_: [KitchenScreen]) {}

    func didTapReset() {}

    func didChangeIsConfirmingReset(_: Bool) {}

    func didConfirmReset() {}
}
