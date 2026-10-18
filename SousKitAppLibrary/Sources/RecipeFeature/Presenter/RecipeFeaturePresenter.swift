import Foundation
import RecipeLibrary
import RecipeScaling
import SousKit

struct RecipeFeaturePresenter: RecipeFeaturePresenterProtocol {
    private let handler: RecipeFeatureHandler
    private let parser: SousParser
    private let preferredScaleStore: PreferredScaleStore
    private let recipeRepository: RecipeRepository
    private let restoration: RecipeFeatureRestoration?
    private let resumesCooking: Bool
    private let viewModel: RecipeFeatureViewModel

    init(
        handler: RecipeFeatureHandler,
        parser: SousParser,
        preferredScaleStore: PreferredScaleStore,
        recipeRepository: RecipeRepository,
        restoration: RecipeFeatureRestoration?,
        resumesCooking: Bool,
        viewModel: RecipeFeatureViewModel
    ) {
        self.handler = handler
        self.parser = parser
        self.preferredScaleStore = preferredScaleStore
        self.recipeRepository = recipeRepository
        self.restoration = restoration
        self.resumesCooking = resumesCooking
        self.viewModel = viewModel
    }

    func viewDidAppear() async {
        // A restoration applies when the recipe first reaches the screen, not to a read coming back from cooking.
        let restores = switch viewModel.recipeContent {
        case .recipe: false
        case .reading, .failure: true
        }
        let recipeContent: RecipeContent

        do {
            // The diagnostics are dropped until there is a screen to report them on.
            let recipe = try await recipeRepository.readRecipe(of: viewModel.recipeEntry).value

            recipeContent = .recipe(read(recipe))
        } catch {
            recipeContent = .failure(error.localizedDescription)
        }

        guard !Task.isCancelled else {
            return
        }

        viewModel.recipeContent = recipeContent

        // A read landing while the sheet is open leaves the field to what the cook is typing.
        if !viewModel.isScaling {
            writeField()
        }

        if restores {
            restore()
        }
    }

    func didChangeIsExpanded(_ isExpanded: Bool, of section: RecipeSection) {
        if isExpanded {
            viewModel.expandedSections.insert(section)
        } else {
            viewModel.expandedSections.remove(section)
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

        guard
            case .recipe(let recipe) = viewModel.recipeContent,
            let value = ScaleNumber.value(of: text)
        else {
            return
        }

        // The field is left as it is being typed, so only the recipe moves.
        rescale(to: RecipeScale(target: recipe.scale.target, value: value))
    }

    func didStepScale(by steps: Double) {
        guard case .recipe(let recipe) = viewModel.recipeContent else {
            return
        }

        apply(recipe.stepped(by: steps))
    }

    func didTapTarget(_ target: ScaleTarget) {
        guard
            case .recipe(let recipe) = viewModel.recipeContent,
            target != recipe.scale.target,
            let counted = recipe.counted(by: target)
        else {
            return
        }

        // The same amount of food, counted the other way, so switching back lands where it started.
        viewModel.recipeContent = .recipe(counted)
        writeField()
        reportRestoration()
    }

    func didTapReset() {
        guard case .recipe(let recipe) = viewModel.recipeContent else {
            return
        }

        apply(recipe.defaultScale)
    }

    func didTapCook() {
        guard case .recipe(let recipe) = viewModel.recipeContent else {
            return
        }

        handler.recipeFeatureDidStartCooking(recipe: recipe.scaled)
    }

    /// The recipe as read, at the scale a cook already chose where they chose one.
    @MainActor
    private func read(_ recipe: Recipe) -> ScaledRecipe {
        let scale = switch viewModel.recipeContent {
        // A default is the file's, so a file that now declares another opens on that one.
        case .recipe(let current): chosenScale(of: current)
        case .reading, .failure: restoration?.scale
        }

        return ScaledRecipe(
            asWritten: recipe,
            parser: parser,
            preferredScale: preferredScaleStore.preferredScale,
            scale: scale
        )
    }

    /// Opens cooking again where it was open when the screen was left, now that the recipe it opens over is read.
    @MainActor
    private func restore() {
        guard
            case .recipe(let recipe) = viewModel.recipeContent,
            resumesCooking,
            // A file edited down to no steps since has nothing to cook, as its screen offers no button to start.
            !recipe.scaled.steps.isEmpty
        else {
            return
        }

        handler.recipeFeatureDidResumeCooking(recipe: recipe.scaled)
    }

    @MainActor
    private func reportRestoration() {
        guard case .recipe(let recipe) = viewModel.recipeContent else {
            return
        }

        handler.recipeFeatureDidChangeRestoration(RecipeFeatureRestoration(scale: chosenScale(of: recipe)))
    }

    /// The scale a cook chose, or `nil` at the recipe's default scale.
    private func chosenScale(of recipe: ScaledRecipe) -> RecipeScale? {
        recipe.isDefault ? nil : recipe.scale
    }

    /// Takes the recipe to the scale and writes the scale in force back into the field.
    @MainActor
    private func apply(_ scale: RecipeScale) {
        rescale(to: scale)
        writeField()
    }

    /// Takes the recipe on screen to the scale, or leaves it where it is.
    @MainActor
    private func rescale(to scale: RecipeScale) {
        guard
            case .recipe(let recipe) = viewModel.recipeContent,
            // A plus held at the top of its range asks for the scale in force on every repeat.
            scale != recipe.scale,
            let rescaled = recipe.rescaled(to: scale)
        else {
            return
        }

        viewModel.recipeContent = .recipe(rescaled)
        reportRestoration()
    }

    @MainActor
    private func writeField() {
        guard case .recipe(let recipe) = viewModel.recipeContent else {
            return
        }

        viewModel.scaleText = ScaleNumber.text(recipe.scale.value)
    }
}
