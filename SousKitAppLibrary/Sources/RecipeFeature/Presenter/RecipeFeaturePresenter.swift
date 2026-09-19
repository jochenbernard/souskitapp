import Foundation
import RecipeLibrary
import SousKit

struct RecipeFeaturePresenter: RecipeFeaturePresenterProtocol {
    private let handler: RecipeFeatureHandler
    private let recipeRepository: RecipeRepository
    private let viewModel: RecipeFeatureViewModel

    init(
        handler: RecipeFeatureHandler,
        recipeRepository: RecipeRepository,
        viewModel: RecipeFeatureViewModel
    ) {
        self.handler = handler
        self.recipeRepository = recipeRepository
        self.viewModel = viewModel
    }

    func viewDidAppear() async {
        let recipeContent: RecipeContent

        do {
            // The diagnostics are dropped until there is a screen to report them on.
            recipeContent = .recipe(try await recipeRepository.readRecipe(of: viewModel.recipeEntry).value)
        } catch {
            recipeContent = .failure(error.localizedDescription)
        }

        guard !Task.isCancelled else {
            return
        }

        viewModel.recipeContent = recipeContent
    }

    func didChangeIsExpanded(_ isExpanded: Bool, of section: RecipeSection) {
        if isExpanded {
            viewModel.expandedSections.insert(section)
        } else {
            viewModel.expandedSections.remove(section)
        }
    }

    func didTapCook() {
        guard case .recipe(let recipe) = viewModel.recipeContent else {
            return
        }

        handler.recipeFeatureDidStartCooking(recipe: recipe)
    }
}
