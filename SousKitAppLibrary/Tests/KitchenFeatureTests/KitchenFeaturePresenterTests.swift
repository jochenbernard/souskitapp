import CookingFeature
import Foundation
@testable import KitchenFeature
import RecipeFeature
import RecipeLibrary
import SousKit
import Testing

@Suite("Kitchen feature presenter", .timeLimit(.minutes(1)))
final class KitchenFeaturePresenterTests: Sendable {
    private let directoryURL: URL

    init() throws {
        let url = URL(filePath: NSTemporaryDirectory())
            .appending(path: "KitchenFeaturePresenterTests.\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        self.directoryURL = url
    }

    deinit {
        try? FileManager.default.removeItem(at: directoryURL)
    }

    private func writeFile(named fileName: String) throws {
        try Data().write(to: directoryURL.appending(path: fileName))
    }

    @discardableResult
    private func writeFile(named fileName: String, _ text: String) throws -> RecipeFile {
        let url = directoryURL.appending(path: fileName)
        try Data(text.utf8).write(to: url)

        return RecipeFile(url: url, availability: .downloaded)
    }

    private func makeViewModel() -> KitchenFeatureViewModel {
        KitchenFeatureViewModel(recipeDirectory: RecipeDirectory(url: directoryURL))
    }

    @MainActor
    private func makePresenter(
        viewModel: KitchenFeatureViewModel,
        handler: KitchenFeatureHandler = KitchenFeatureHandlerStub()
    ) -> KitchenFeaturePresenter {
        let recipeDirectory = RecipeDirectory(url: directoryURL)

        return KitchenFeaturePresenter(
            cookingFeatureFactory: CookingFeatureFactory(idleTimer: IdleTimerStub()),
            handler: handler,
            recipeDirectoryMonitor: RecipeDirectoryMonitor(
                recipeDirectory: recipeDirectory,
                settleDelay: .milliseconds(20)
            ),
            recipeFeatureFactory: RecipeFeatureFactory(recipeDirectory: recipeDirectory),
            viewModel: viewModel
        )
    }

    /// Whether the view model reaches the given names, waiting until it does or the suite's time
    /// limit ends the test.
    @MainActor
    private func names(reach expected: [String], in viewModel: KitchenFeatureViewModel) async -> Bool {
        while !Task.isCancelled {
            if
                case .recipes(let recipeFiles) = viewModel.recipeList,
                recipeFiles.map(\.name) == expected
            {
                return true
            }

            try? await Task.sleep(for: .milliseconds(10))
        }

        return false
    }

    @MainActor
    @Test("the view model starts out reading")
    func readingBeforeTheFirstRead() {
        guard case .reading = makeViewModel().recipeList else {
            Issue.record("The recipe list did not start out reading.")
            return
        }
    }

    @MainActor
    @Test("the recipes in the directory reach the view model")
    func recipesReachTheViewModel() async throws {
        try writeFile(named: "crepes.sous")
        try writeFile(named: "boeuf-bourguignon.sous")

        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)
        let task = Task {
            await presenter.viewDidAppear()
        }
        defer {
            task.cancel()
        }

        #expect(await names(reach: ["boeuf bourguignon", "crepes"], in: viewModel))
    }

    @MainActor
    @Test("a recipe added to the directory reaches the view model")
    func addedRecipeReachesTheViewModel() async throws {
        try writeFile(named: "crepes.sous")

        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)
        let task = Task {
            await presenter.viewDidAppear()
        }
        defer {
            task.cancel()
        }

        #expect(await names(reach: ["crepes"], in: viewModel))

        try writeFile(named: "brioche.sous")

        #expect(await names(reach: ["brioche", "crepes"], in: viewModel))
    }

    @MainActor
    @Test("a directory that is gone reaches the view model as a failure")
    func failureReachesTheViewModel() async throws {
        try FileManager.default.removeItem(at: directoryURL)

        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)
        let task = Task {
            await presenter.viewDidAppear()
        }
        defer {
            task.cancel()
        }

        while true {
            if case .failure(let message) = viewModel.recipeList {
                #expect(!message.isEmpty)
                return
            }

            try await Task.sleep(for: .milliseconds(10))
        }
    }

    @MainActor
    @Test("a recipe pushed on the stack reaches the view model with a feature to render it")
    func recipePathReachesTheViewModel() throws {
        let recipeFile = try writeFile(named: "crepes.sous", "Whisk.")
        let viewModel = makeViewModel()

        makePresenter(viewModel: viewModel).didChangeScreenPath([.recipe(recipeFile)])

        #expect(viewModel.screenPath == [.recipe(recipeFile)])
        #expect(viewModel.openRecipe?.recipeFile == recipeFile)
    }

    @MainActor
    @Test("popping leaves the recipe in place, so it has something to animate away")
    func poppingKeepsTheOpenRecipe() throws {
        let recipeFile = try writeFile(named: "crepes.sous", "Whisk.")
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didChangeScreenPath([.recipe(recipeFile)])
        presenter.didChangeScreenPath([])

        #expect(viewModel.screenPath.isEmpty)
        #expect(viewModel.openRecipe?.recipeFile == recipeFile)
    }

    @MainActor
    @Test("pushing another recipe after a pop replaces the one left behind")
    func pushingAfterAPopReplacesTheOpenRecipe() throws {
        let crepes = try writeFile(named: "crepes.sous", "Whisk.")
        let brioche = try writeFile(named: "brioche.sous", "Knead.")
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didChangeScreenPath([.recipe(crepes)])
        presenter.didChangeScreenPath([])
        presenter.didChangeScreenPath([.recipe(brioche)])

        #expect(viewModel.openRecipe?.recipeFile == brioche)
    }

    @MainActor
    @Test("a recipe pushed again keeps the feature already built for it")
    func pushingTheSameRecipeKeepsItsFeature() throws {
        let recipeFile = try writeFile(named: "crepes.sous", "Whisk.")
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didChangeScreenPath([.recipe(recipeFile)])
        let first = viewModel.openRecipe
        presenter.didChangeScreenPath([.recipe(recipeFile)])

        #expect(first != nil)
        #expect(viewModel.openRecipe?.recipeFile == first?.recipeFile)
    }

    @MainActor
    @Test("cooking a recipe pushes it on the stack with a feature to render it")
    func cookingPushesTheCookingScreen() throws {
        let recipeFile = try writeFile(named: "crepes.sous", "Whisk it.")
        let recipe = SousParser().parseRecipe("Whisk it.").value
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didChangeScreenPath([.recipe(recipeFile)])
        presenter.recipeFeatureDidStartCooking(recipe: recipe)

        #expect(viewModel.screenPath == [.recipe(recipeFile), .cooking(recipe)])
        #expect(viewModel.openCooking?.recipe == recipe)
    }

    @MainActor
    @Test("popping the cooking screen leaves the recipe under it open")
    func poppingCookingKeepsTheOpenRecipe() throws {
        let recipeFile = try writeFile(named: "crepes.sous", "Whisk it.")
        let recipe = SousParser().parseRecipe("Whisk it.").value
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didChangeScreenPath([.recipe(recipeFile)])
        presenter.recipeFeatureDidStartCooking(recipe: recipe)
        presenter.didChangeScreenPath([.recipe(recipeFile)])

        #expect(viewModel.screenPath == [.recipe(recipeFile)])
        #expect(viewModel.openRecipe?.recipeFile == recipeFile)
        #expect(viewModel.openCooking?.recipe == recipe)
    }

    @MainActor
    @Test("exiting the cooking screen pops back to the recipe")
    func exitingCookingPopsToTheRecipe() throws {
        let recipeFile = try writeFile(named: "crepes.sous", "Whisk it.")
        let recipe = SousParser().parseRecipe("Whisk it.").value
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didChangeScreenPath([.recipe(recipeFile)])
        presenter.recipeFeatureDidStartCooking(recipe: recipe)
        presenter.cookingFeatureDidExit()

        #expect(viewModel.screenPath == [.recipe(recipeFile)])
    }

    @MainActor
    @Test("an exit with no cooking screen on top leaves the stack alone")
    func exitWithoutCookingKeepsTheStack() throws {
        let recipeFile = try writeFile(named: "crepes.sous", "Whisk it.")
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didChangeScreenPath([.recipe(recipeFile)])
        presenter.cookingFeatureDidExit()

        #expect(viewModel.screenPath == [.recipe(recipeFile)])
    }

    @MainActor
    @Test("the reset opens the confirmation and reports nothing yet")
    func resetOpensTheConfirmation() {
        let handler = KitchenFeatureHandlerStub()
        let viewModel = makeViewModel()

        makePresenter(viewModel: viewModel, handler: handler).didTapReset()

        #expect(viewModel.isConfirmingReset)
        #expect(handler.resetCount == 0)
    }

    @MainActor
    @Test("a confirmed reset closes the confirmation and reports once")
    func confirmedResetReports() {
        let handler = KitchenFeatureHandlerStub()
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel, handler: handler)

        presenter.didTapReset()
        presenter.didConfirmReset()

        #expect(!viewModel.isConfirmingReset)
        #expect(handler.resetCount == 1)
    }

    @MainActor
    @Test("a dismissed confirmation reports nothing")
    func dismissedConfirmationReportsNothing() {
        let handler = KitchenFeatureHandlerStub()
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel, handler: handler)

        presenter.didTapReset()
        presenter.didChangeIsConfirmingReset(false)

        #expect(!viewModel.isConfirmingReset)
        #expect(handler.resetCount == 0)
    }
}
