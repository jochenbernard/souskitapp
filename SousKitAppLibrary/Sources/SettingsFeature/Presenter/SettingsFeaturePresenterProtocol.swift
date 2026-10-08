import Foundation
import RecipeLibrary
import RecipeScaling

/// What ``SettingsFeatureView`` reports to.
protocol SettingsFeaturePresenterProtocol: ScaleSheetPresenterProtocol {
    @MainActor
    func didTapDone()

    @MainActor
    func didTapChangeDirectory()

    @MainActor
    func didChangeIsChoosingDirectory(_ isChoosing: Bool)

    @MainActor
    func didChooseDirectory(_ result: Result<URL, Error>)

    @MainActor
    func didTapScale()

    @MainActor
    func didSelectRecipeRepositoryKind(_ recipeRepositoryKind: RecipeRepositoryKind)

    @MainActor
    func didTapResetApp()

    @MainActor
    func didChangeIsConfirmingReset(_ isConfirming: Bool)

    @MainActor
    func didConfirmReset()
}
