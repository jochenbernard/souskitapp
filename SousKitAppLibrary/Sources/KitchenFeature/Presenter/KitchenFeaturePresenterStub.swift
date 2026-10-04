import RecipeLibrary

struct KitchenFeaturePresenterStub: KitchenFeaturePresenterProtocol {
    func viewDidAppear() {}

    func didBecomeActive() {}

    func didEnterBackground() {}

    func didChangeScreenPath(_: [KitchenScreen]) {}

    func didDismissCooking() {}

    func didSelectRecipeRepositoryKind(_: RecipeRepositoryKind) {}

    func didTapReset() {}

    func didChangeIsConfirmingReset(_: Bool) {}

    func didConfirmReset() {}
}
