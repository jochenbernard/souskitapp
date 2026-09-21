import Foundation
import RecipeLibrary

struct OnboardingFeaturePresenter: OnboardingFeaturePresenterProtocol {
    private let handler: OnboardingFeatureHandler
    private let recipeRepositoryStore: RecipeRepositoryStore
    private let viewModel: OnboardingFeatureViewModel

    init(
        handler: OnboardingFeatureHandler,
        recipeRepositoryStore: RecipeRepositoryStore,
        viewModel: OnboardingFeatureViewModel
    ) {
        self.handler = handler
        self.recipeRepositoryStore = recipeRepositoryStore
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
            let recipeRepository = try recipeRepositoryStore.connectRecipeDirectory(at: url)
            viewModel.failureMessage = nil
            handler.onboardingFeatureDidFinish(recipeRepository: recipeRepository)
        } catch {
            viewModel.failureMessage = error.localizedDescription
        }
    }

    func didSelectRecipeRepositoryKind(_ recipeRepositoryKind: RecipeRepositoryKind) {
        handler.onboardingFeatureDidSelectRecipeRepositoryKind(recipeRepositoryKind)
    }
}
