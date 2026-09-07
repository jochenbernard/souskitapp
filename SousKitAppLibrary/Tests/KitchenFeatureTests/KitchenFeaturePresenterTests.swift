import Foundation
@testable import KitchenFeature
import RecipeFeature
import RecipeLibrary
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

    private func makePresenter(viewModel: KitchenFeatureViewModel) -> KitchenFeaturePresenter {
        let recipeDirectory = RecipeDirectory(url: directoryURL)

        return KitchenFeaturePresenter(
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

        #expect(await names(reach: ["Boeuf Bourguignon", "Crepes"], in: viewModel))
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

        #expect(await names(reach: ["Crepes"], in: viewModel))

        try writeFile(named: "brioche.sous")

        #expect(await names(reach: ["Brioche", "Crepes"], in: viewModel))
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

        makePresenter(viewModel: viewModel).didChangeRecipePath([recipeFile])

        #expect(viewModel.recipePath == [recipeFile])
        #expect(viewModel.openRecipe?.recipeFile == recipeFile)
    }

    @MainActor
    @Test("popping the last recipe takes the open recipe with it")
    func poppingClearsTheOpenRecipe() throws {
        let recipeFile = try writeFile(named: "crepes.sous", "Whisk.")
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didChangeRecipePath([recipeFile])
        presenter.didChangeRecipePath([])

        #expect(viewModel.recipePath.isEmpty)
        #expect(viewModel.openRecipe == nil)
    }

    @MainActor
    @Test("a recipe pushed again keeps the feature already built for it")
    func pushingTheSameRecipeKeepsItsFeature() throws {
        let recipeFile = try writeFile(named: "crepes.sous", "Whisk.")
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didChangeRecipePath([recipeFile])
        let first = viewModel.openRecipe
        presenter.didChangeRecipePath([recipeFile])

        #expect(first != nil)
        #expect(viewModel.openRecipe?.recipeFile == first?.recipeFile)
    }
}
