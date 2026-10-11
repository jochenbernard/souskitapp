import Foundation
import RecipeLibrary
import RecipeScaling

struct SettingsFeaturePresenterStub: SettingsFeaturePresenterProtocol {
    func didTapDone() {}

    func didTapChangeDirectory() {}

    func didChangeIsChoosingDirectory(_: Bool) {}

    func didChooseDirectory(_: Result<URL, Error>) {}

    func didTapScale() {}

    func didChangeIsScaling(_: Bool) {}

    func didChangeScaleText(_: String) {}

    func didStepScale(by _: Double) {}

    func didTapTarget(_: ScaleTarget) {}

    func didTapReset() {}

    func didSelectRecipeRepositoryKind(_: RecipeRepositoryKind) {}

    func didTapResetApp() {}

    func didChangeIsConfirmingReset(_: Bool) {}

    func didConfirmReset() {}
}
