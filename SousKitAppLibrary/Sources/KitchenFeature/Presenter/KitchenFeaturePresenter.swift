import Foundation
import RecipeLibrary

struct KitchenFeaturePresenter: KitchenFeaturePresenterProtocol {
    private let recipeDirectoryMonitor: RecipeDirectoryMonitor
    private let viewModel: KitchenFeatureViewModel

    init(
        recipeDirectoryMonitor: RecipeDirectoryMonitor,
        viewModel: KitchenFeatureViewModel
    ) {
        self.recipeDirectoryMonitor = recipeDirectoryMonitor
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
}
