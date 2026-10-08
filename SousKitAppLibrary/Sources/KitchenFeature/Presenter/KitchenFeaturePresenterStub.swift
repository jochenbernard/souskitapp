struct KitchenFeaturePresenterStub: KitchenFeaturePresenterProtocol {
    func viewDidAppear() {}

    func didBecomeActive() {}

    func didEnterBackground() {}

    func didChangeScreenPath(_: [KitchenScreen]) {}

    func didDismissCooking() {}

    func didTapSettings() {}

    func didDismissSettings() {}

    func didFinishDismissingSettings() {}
}
