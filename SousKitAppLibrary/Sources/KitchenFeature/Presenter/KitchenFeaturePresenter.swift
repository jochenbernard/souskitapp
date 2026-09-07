import Foundation
import RecipeFeature
import RecipeLibrary

struct KitchenFeaturePresenter: KitchenFeaturePresenterProtocol {
    private let recipeDirectoryMonitor: RecipeDirectoryMonitor
    private let recipeFeatureFactory: RecipeFeatureFactory
    private let viewModel: KitchenFeatureViewModel

    init(
        recipeDirectoryMonitor: RecipeDirectoryMonitor,
        recipeFeatureFactory: RecipeFeatureFactory,
        viewModel: KitchenFeatureViewModel
    ) {
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

    func didChangeRecipePath(_ recipePath: [RecipeFile]) {
        viewModel.recipePath = recipePath

        guard let recipeFile = recipePath.last else {
            viewModel.openRecipe = nil
            return
        }

        guard viewModel.openRecipe?.recipeFile != recipeFile else {
            return
        }

        viewModel.openRecipe = OpenRecipe(
            recipeFile: recipeFile,
            feature: recipeFeatureFactory.makeRecipeFeature(recipeFile: recipeFile)
        )
    }
}
