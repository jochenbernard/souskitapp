struct KitchenFeaturePresenterStub: KitchenFeaturePresenterProtocol {
    func viewDidAppear() {}

    func didBecomeActive() {}

    func didChangeScreenPath(_: [KitchenScreen]) {}

    func didDismissCooking() {}
}
