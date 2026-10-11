struct KitchenFeaturePresenterStub: KitchenFeaturePresenterProtocol {
    func viewDidAppear() {}

    func didBecomeActive() {}

    func didChangePushedScreen(_: KitchenScreen?) {}

    func didDismissCooking() {}
}
