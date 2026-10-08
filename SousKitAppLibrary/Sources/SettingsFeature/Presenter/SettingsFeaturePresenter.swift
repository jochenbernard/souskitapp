import Foundation
import RecipeLibrary
import RecipeScaling

struct SettingsFeaturePresenter: SettingsFeaturePresenterProtocol {
    private let handler: SettingsFeatureHandler
    private let preferredScaleStore: PreferredScaleStore
    private let recipeRepositoryStore: RecipeRepositoryStore
    private let viewModel: SettingsFeatureViewModel

    init(
        handler: SettingsFeatureHandler,
        preferredScaleStore: PreferredScaleStore,
        recipeRepositoryStore: RecipeRepositoryStore,
        viewModel: SettingsFeatureViewModel
    ) {
        self.handler = handler
        self.preferredScaleStore = preferredScaleStore
        self.recipeRepositoryStore = recipeRepositoryStore
        self.viewModel = viewModel
    }

    func didTapDone() {
        handler.settingsFeatureDidFinish()
    }

    func didTapChangeDirectory() {
        viewModel.failureMessage = nil
        viewModel.isChoosingDirectory = true
    }

    func didChangeIsChoosingDirectory(_ isChoosing: Bool) {
        viewModel.isChoosingDirectory = isChoosing
    }

    /// Records the directory before reporting it, so the app never moves to a directory it cannot get back to after
    /// this launch.
    func didChooseDirectory(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let recipeRepository = try recipeRepositoryStore.connectRecipeDirectory(at: url)
            viewModel.failureMessage = nil
            handler.settingsFeatureDidConnectRecipeRepository(recipeRepository)
        } catch {
            viewModel.failureMessage = error.localizedDescription
        }
    }

    func didTapScale() {
        viewModel.isScaling = true
    }

    func didChangeIsScaling(_ isScaling: Bool) {
        viewModel.isScaling = isScaling

        // A field left half typed reads the scale in force again, rather than opening on it.
        if !isScaling {
            writeField()
        }
    }

    func didChangeScaleText(_ text: String) {
        viewModel.scaleText = text

        guard let value = ScaleNumber.value(of: text) else {
            return
        }

        // The field is left as it is being typed, so only the scale moves.
        remember(RecipeScale(target: viewModel.scale.target, value: value))
    }

    func didStepScale(by steps: Double) {
        let scale = viewModel.scale

        apply(
            RecipeScale(
                target: scale.target,
                value: scale.target.stepped(
                    scale.value,
                    by: steps,
                    declared: 1.0
                )
            )
        )
    }

    func didTapTarget(_ target: ScaleTarget) {
        guard target != viewModel.scale.target else {
            return
        }

        // Servings and a multiple do not convert without a recipe, so each starts on a number of its own.
        let value = switch target {
        case .servings: 4.0
        case .multiplier, .yield: 1.0
        }

        apply(RecipeScale(target: target, value: value))
    }

    func didTapReset() {
        apply(RecipeScale(.asWritten))
    }

    func didSelectRecipeRepositoryKind(_ recipeRepositoryKind: RecipeRepositoryKind) {
        handler.settingsFeatureDidSelectRecipeRepositoryKind(recipeRepositoryKind)
    }

    func didTapResetApp() {
        viewModel.isConfirmingReset = true
    }

    func didChangeIsConfirmingReset(_ isConfirming: Bool) {
        viewModel.isConfirmingReset = isConfirming
    }

    func didConfirmReset() {
        viewModel.isConfirmingReset = false
        handler.settingsFeatureDidConfirmReset()
    }

    /// Takes the scale to another and writes it back into the field.
    @MainActor
    private func apply(_ scale: RecipeScale) {
        remember(scale)
        writeField()
    }

    @MainActor
    private func remember(_ scale: RecipeScale) {
        guard
            // A plus held at the top of its range asks for the scale in force on every repeat.
            scale != viewModel.scale,
            let preferredScale = PreferredScale(scale)
        else {
            return
        }

        viewModel.scale = scale
        preferredScaleStore.remember(preferredScale)
    }

    @MainActor
    private func writeField() {
        viewModel.scaleText = ScaleNumber.text(viewModel.scale.value)
    }
}
