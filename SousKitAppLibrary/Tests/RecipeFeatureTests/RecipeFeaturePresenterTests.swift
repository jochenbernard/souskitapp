import Foundation
@testable import RecipeFeature
import RecipeLibrary
import SousKit
import Testing

@Suite("Recipe feature presenter", .timeLimit(.minutes(1)))
final class RecipeFeaturePresenterTests: Sendable {
    private let directoryURL: URL

    init() throws {
        let url = URL(filePath: NSTemporaryDirectory())
            .appending(path: "RecipeFeaturePresenterTests.\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        self.directoryURL = url
    }

    deinit {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    private func writeFile(named fileName: String, _ text: String) throws -> RecipeFile {
        let url = directoryURL.appending(path: fileName)
        try Data(text.utf8).write(to: url)

        return RecipeFile(url: url, availability: .downloaded)
    }

    private func makePresenter(
        viewModel: RecipeFeatureViewModel,
        handler: RecipeFeatureHandler = RecipeFeatureHandlerSpy()
    ) -> RecipeFeaturePresenter {
        RecipeFeaturePresenter(
            handler: handler,
            recipeReader: RecipeReader(recipeDirectory: RecipeDirectory(url: directoryURL)),
            viewModel: viewModel
        )
    }

    @MainActor
    @Test("the view model starts out reading")
    func readingBeforeTheFirstRead() throws {
        let recipeFile = try writeFile(named: "crepes.sous", "Whisk.")

        guard case .reading = RecipeFeatureViewModel(recipeFile: recipeFile).recipeContent else {
            Issue.record("The recipe content did not start out reading.")
            return
        }
    }

    @MainActor
    @Test("a parsed recipe reaches the view model")
    func recipeReachesTheViewModel() async throws {
        let recipeFile = try writeFile(
            named: "crepes.sous",
            """
            ---
            title: Crepes
            servings: 4
            ---

            Whisk @{4} eggs@ for ~1 min~ in a #bowl#.
            """
        )
        let viewModel = RecipeFeatureViewModel(recipeFile: recipeFile)

        await makePresenter(viewModel: viewModel).viewDidAppear()

        guard case .recipe(let recipe) = viewModel.recipeContent else {
            Issue.record("The recipe did not reach the view model.")
            return
        }

        #expect(recipe.metadata.title == "Crepes")
        #expect(recipe.metadata.servings == 4.0)
        #expect(recipe.ingredients.map(\.name) == ["eggs"])
        #expect(recipe.cookware.map(\.name) == ["bowl"])
        #expect(recipe.steps.count == 1)
    }

    @MainActor
    @Test("an empty recipe reaches the view model holding nothing")
    func emptyRecipeReachesTheViewModel() async throws {
        let recipeFile = try writeFile(named: "empty.sous", "")
        let viewModel = RecipeFeatureViewModel(recipeFile: recipeFile)

        await makePresenter(viewModel: viewModel).viewDidAppear()

        guard case .recipe(let recipe) = viewModel.recipeContent else {
            Issue.record("The recipe did not reach the view model.")
            return
        }

        #expect(recipe.steps.isEmpty)
    }

    @MainActor
    @Test("the ingredients and the steps open, and the cookware stays closed")
    func sectionsOpenByDefault() throws {
        let recipeFile = try writeFile(named: "crepes.sous", "Whisk.")

        let viewModel = RecipeFeatureViewModel(recipeFile: recipeFile)

        #expect(viewModel.expandedSections == [.ingredients, .steps])
    }

    @MainActor
    @Test("tapping a closed section opens it")
    func openingASection() throws {
        let recipeFile = try writeFile(named: "crepes.sous", "Whisk.")
        let viewModel = RecipeFeatureViewModel(recipeFile: recipeFile)

        makePresenter(viewModel: viewModel).didToggleSection(.cookware)

        #expect(viewModel.expandedSections == [.ingredients, .cookware, .steps])
    }

    @MainActor
    @Test("tapping an open section closes it")
    func closingASection() throws {
        let recipeFile = try writeFile(named: "crepes.sous", "Whisk.")
        let viewModel = RecipeFeatureViewModel(recipeFile: recipeFile)

        makePresenter(viewModel: viewModel).didToggleSection(.ingredients)

        #expect(viewModel.expandedSections == [.steps])
    }

    @MainActor
    @Test("tapping a section twice leaves it as it was")
    func togglingASectionBack() throws {
        let recipeFile = try writeFile(named: "crepes.sous", "Whisk.")
        let viewModel = RecipeFeatureViewModel(recipeFile: recipeFile)
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didToggleSection(.cookware)
        presenter.didToggleSection(.cookware)

        #expect(viewModel.expandedSections == RecipeSection.openByDefault)
    }

    @MainActor
    @Test("tapping cook reports the recipe that was read")
    func cookingReportsTheRecipe() async throws {
        let recipeFile = try writeFile(
            named: "crepes.sous",
            """
            ---
            title: Crepes
            ---

            Whisk it.
            """
        )
        let viewModel = RecipeFeatureViewModel(recipeFile: recipeFile)
        let handler = RecipeFeatureHandlerSpy()
        let presenter = makePresenter(viewModel: viewModel, handler: handler)

        await presenter.viewDidAppear()
        presenter.didTapCook()

        #expect(handler.cookedRecipes.map(\.metadata.title) == ["Crepes"])
    }

    @MainActor
    @Test("tapping cook before the recipe is read reports nothing")
    func cookingBeforeTheRecipeIsRead() throws {
        let recipeFile = try writeFile(named: "crepes.sous", "Whisk.")
        let viewModel = RecipeFeatureViewModel(recipeFile: recipeFile)
        let handler = RecipeFeatureHandlerSpy()

        makePresenter(viewModel: viewModel, handler: handler).didTapCook()

        #expect(handler.cookedRecipes.isEmpty)
    }

    @MainActor
    @Test("a recipe that is gone reaches the view model as a failure")
    func failureReachesTheViewModel() async throws {
        let recipeFile = try writeFile(named: "crepes.sous", "Whisk.")
        try FileManager.default.removeItem(at: recipeFile.url)
        let viewModel = RecipeFeatureViewModel(recipeFile: recipeFile)

        await makePresenter(viewModel: viewModel).viewDidAppear()

        guard case .failure(let message) = viewModel.recipeContent else {
            Issue.record("The failure did not reach the view model.")
            return
        }

        #expect(!message.isEmpty)
    }
}
