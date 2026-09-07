import Foundation
import RecipeLibrary

struct RecipeFeaturePresenter: RecipeFeaturePresenterProtocol {
    private let recipeTextReader: RecipeTextReader
    private let viewModel: RecipeFeatureViewModel

    init(
        recipeTextReader: RecipeTextReader,
        viewModel: RecipeFeatureViewModel
    ) {
        self.recipeTextReader = recipeTextReader
        self.viewModel = viewModel
    }

    func viewDidAppear() async {
        viewModel.recipeText = .reading

        let result = await Self.readText(of: viewModel.recipeFile, with: recipeTextReader)

        guard !Task.isCancelled else {
            return
        }

        switch result {
        case .success(let text):
            viewModel.recipeText = .text(text)

        case .failure(let error):
            viewModel.recipeText = .failure(error.localizedDescription)
        }
    }

    /// Reads off the main actor, where a recipe still in iCloud has to be fetched first.
    @concurrent
    nonisolated private static func readText(
        of recipeFile: RecipeFile,
        with reader: RecipeTextReader
    ) async -> Result<String, Error> {
        Result(catching: { try reader.readText(of: recipeFile) })
    }
}
