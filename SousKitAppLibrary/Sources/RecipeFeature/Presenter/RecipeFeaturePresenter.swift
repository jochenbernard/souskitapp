import Foundation
import RecipeLibrary
import SousKit

struct RecipeFeaturePresenter: RecipeFeaturePresenterProtocol {
    private let recipeReader: RecipeReader
    private let viewModel: RecipeFeatureViewModel

    init(
        recipeReader: RecipeReader,
        viewModel: RecipeFeatureViewModel
    ) {
        self.recipeReader = recipeReader
        self.viewModel = viewModel
    }

    func viewDidAppear() async {
        viewModel.recipeContent = .reading

        let result = await Self.readRecipe(of: viewModel.recipeFile, with: recipeReader)

        guard !Task.isCancelled else {
            return
        }

        switch result {
        case .success(let parsed):
            // The diagnostics are dropped until there is a screen to report them on.
            viewModel.recipeContent = .recipe(parsed.value)

        case .failure(let error):
            viewModel.recipeContent = .failure(error.localizedDescription)
        }
    }

    /// Reads off the main actor, where a recipe still in iCloud has to be fetched first.
    @concurrent
    nonisolated private static func readRecipe(
        of recipeFile: RecipeFile,
        with reader: RecipeReader
    ) async -> Result<Parsed<Recipe>, Error> {
        Result(catching: { try reader.readRecipe(of: recipeFile) })
    }
}
