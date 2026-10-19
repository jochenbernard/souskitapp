struct KitchenFeaturePresenterStub: KitchenFeaturePresenterProtocol {
    func viewDidAppear() {}

    func didBecomeActive() {}

    func didPush(_: KitchenScreen, from _: KitchenScreen?) {}

    func didPop(toCount _: Int) {}

    func didDismissCooking() {}
}
