import RecipeLibrary

struct KitchenFeaturePresenterStub: KitchenFeaturePresenterProtocol {
    func viewDidAppear() {}

    func didBecomeActive() {}

    func didChangeRecipePath(_: [RecipeFile]) {}
}
