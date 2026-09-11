import CookingFeature
import Foundation
import RecipeFeature
import RecipeLibrary
import SousKit

struct KitchenFeaturePresenter: KitchenFeaturePresenterProtocol, RecipeFeatureHandler, CookingFeatureHandler {
    private let cookingFeatureFactory: CookingFeatureFactory
    private let recipeDirectoryMonitor: RecipeDirectoryMonitor
    private let recipeFeatureFactory: RecipeFeatureFactory
    private let viewModel: KitchenFeatureViewModel

    init(
        cookingFeatureFactory: CookingFeatureFactory,
        recipeDirectoryMonitor: RecipeDirectoryMonitor,
        recipeFeatureFactory: RecipeFeatureFactory,
        viewModel: KitchenFeatureViewModel
    ) {
        self.cookingFeatureFactory = cookingFeatureFactory
        self.recipeDirectoryMonitor = recipeDirectoryMonitor
        self.recipeFeatureFactory = recipeFeatureFactory
        self.viewModel = viewModel
    }

    func viewDidAppear() async {
        for await result in recipeDirectoryMonitor.recipeFiles() {
            switch result {
            case .success(let recipeFiles):
                viewModel.recipeList = .recipes(recipeFiles)

            case .failure(let error):
                viewModel.recipeList = .failure(error.localizedDescription)
            }
        }
    }

    func didBecomeActive() {
        recipeDirectoryMonitor.refresh()
    }

    func didChangeScreenPath(_ screenPath: [KitchenScreen]) {
        viewModel.screenPath = screenPath

        // A pop leaves the screen it popped in place: clearing it empties that screen while it
        // is still animating away. The next push replaces it.
        switch screenPath.last {
        case .recipe(let recipeFile):
            openRecipe(recipeFile)

        case .cooking(let recipe):
            openCooking(recipe)

        case nil:
            break
        }
    }

    func recipeFeatureDidStartCooking(recipe: Recipe) {
        didChangeScreenPath(viewModel.screenPath + [.cooking(recipe)])
    }

    func cookingFeatureDidExit() {
        guard case .cooking = viewModel.screenPath.last else {
            return
        }

        didChangeScreenPath(Array(viewModel.screenPath.dropLast()))
    }

    @MainActor
    private func openRecipe(_ recipeFile: RecipeFile) {
        guard viewModel.openRecipe?.recipeFile != recipeFile else {
            return
        }

        viewModel.openRecipe = OpenRecipe(
            recipeFile: recipeFile,
            feature: recipeFeatureFactory.makeRecipeFeature(
                recipeFile: recipeFile,
                handler: self
            )
        )
    }

    @MainActor
    private func openCooking(_ recipe: Recipe) {
        guard viewModel.openCooking?.recipe != recipe else {
            return
        }

        viewModel.openCooking = OpenCooking(
            recipe: recipe,
            feature: cookingFeatureFactory.makeCookingFeature(
                recipe: recipe,
                handler: self
            )
        )
    }
}
