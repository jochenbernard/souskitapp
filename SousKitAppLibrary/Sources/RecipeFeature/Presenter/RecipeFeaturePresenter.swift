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
            let recipe = try await recipeRepository.readRecipe(of: viewModel.recipeEntry).value

            recipeContent = .recipe(read(recipe))
        } catch {
            recipeContent = .failure(error.localizedDescription)
        }

        guard !Task.isCancelled else {
            return
        }

        viewModel.recipeContent = recipeContent
        writeField()
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
        _ = scaled(to: RecipeScale(target: recipe.scale.target, value: value))
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
            let value = recipe.value(of: target)
        else {
            return
        }

        // The same amount of food, counted the other way.
        apply(RecipeScale(target: target, value: value))
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

    /// The recipe as read, at the scale the screen already stands at where it holds one.
    @MainActor
    private func read(_ recipe: Recipe) -> ScaledRecipe {
        guard case .recipe(let current) = viewModel.recipeContent else {
            return ScaledRecipe(asWritten: recipe)
        }

        return ScaledRecipe(asWritten: recipe, scale: current.scale) ?? ScaledRecipe(asWritten: recipe)
    }

    /// Takes the recipe to the scale and writes that back into the field.
    @MainActor
    private func apply(_ scale: RecipeScale) {
        guard let recipe = scaled(to: scale) else {
            return
        }

        writeField(of: recipe)
    }

    /// Takes the recipe on screen to the scale, or leaves it where it is.
    @MainActor
    private func scaled(to scale: RecipeScale) -> ScaledRecipe? {
        guard
            case .recipe(let recipe) = viewModel.recipeContent,
            let scaled = ScaledRecipe(asWritten: recipe.asWritten, scale: scale)
        else {
            return nil
        }

        viewModel.recipeContent = .recipe(scaled)

        return scaled
    }

    @MainActor
    private func writeField() {
        guard case .recipe(let recipe) = viewModel.recipeContent else {
            return
        }

        writeField(of: recipe)
    }

    @MainActor
    private func writeField(of recipe: ScaledRecipe) {
        viewModel.scaleText = ScaleNumber.text(recipe.scale.value)
    }
}
