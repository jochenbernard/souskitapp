import RecipeLibrary

struct KitchenFeaturePresenterStub: KitchenFeaturePresenterProtocol {
    func viewDidAppear() {}

    func didBecomeActive() {}

    func didChangeScreenPath(_: [KitchenScreen]) {}

    func didSelectRecipeRepositoryKind(_: RecipeRepositoryKind) {}

    func didTapReset() {}

    func didChangeIsConfirmingReset(_: Bool) {}

    func didConfirmReset() {}
}
