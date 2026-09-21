import Foundation
import RecipeLibrary

struct OnboardingFeaturePresenterStub: OnboardingFeaturePresenterProtocol {
    func didTapChooseDirectory() {}

    func didChangeIsChoosingDirectory(_: Bool) {}

    func didChooseDirectory(_: Result<URL, Error>) {}

    func didSelectRecipeRepositoryKind(_: RecipeRepositoryKind) {}
}
