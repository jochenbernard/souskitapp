struct KitchenFeaturePresenterStub: KitchenFeaturePresenterProtocol {
    func stackDidAppear() {}

    func didBecomeActive() {}

    func didPush(_: KitchenScreen, from _: KitchenScreen?) {}

    func didPop(toCount _: Int) {}

    func didChangeSearchText(_: String, in _: [String]) {}

    func didDismissCooking() {}
}
