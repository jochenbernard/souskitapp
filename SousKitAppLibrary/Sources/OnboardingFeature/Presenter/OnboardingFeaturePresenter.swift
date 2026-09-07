import Foundation
import RecipeLibrary

struct OnboardingFeaturePresenter: OnboardingFeaturePresenterProtocol {
    private let handler: OnboardingFeatureHandler
    private let recipeDirectoryStore: RecipeDirectoryStore
    private let viewModel: OnboardingFeatureViewModel

    init(
        handler: OnboardingFeatureHandler,
        recipeDirectoryStore: RecipeDirectoryStore,
        viewModel: OnboardingFeatureViewModel
    ) {
        self.handler = handler
        self.recipeDirectoryStore = recipeDirectoryStore
        self.viewModel = viewModel
    }

    func didTapChooseDirectory() {
        viewModel.failureMessage = nil
        viewModel.isChoosingDirectory = true
    }

    func didChangeIsChoosingDirectory(_ isChoosing: Bool) {
        viewModel.isChoosingDirectory = isChoosing
    }

    /// Records the directory before reporting it, so a directory the app cannot get back to
    /// after this launch never becomes the one onboarding finished on.
    func didChooseDirectory(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            try recipeDirectoryStore.setRecipeDirectory(at: url)
            viewModel.failureMessage = nil
            handler.onboardingFeatureDidFinish(recipeDirectory: RecipeDirectory(url: url))
        } catch {
            viewModel.failureMessage = error.localizedDescription
        }
    }
}
