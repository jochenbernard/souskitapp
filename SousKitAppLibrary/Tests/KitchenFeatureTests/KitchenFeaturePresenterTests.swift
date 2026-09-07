import Foundation
@testable import KitchenFeature
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

    private func makeViewModel() -> KitchenFeatureViewModel {
        KitchenFeatureViewModel(recipeDirectory: RecipeDirectory(url: directoryURL))
    }

    private func makePresenter(viewModel: KitchenFeatureViewModel) -> KitchenFeaturePresenter {
        KitchenFeaturePresenter(
            recipeDirectoryMonitor: RecipeDirectoryMonitor(
                recipeDirectory: RecipeDirectory(url: directoryURL),
                settleDelay: .milliseconds(20)
            ),
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

    @Test("the view model starts out reading")
    @MainActor
    func readingBeforeTheFirstRead() {
        guard case .reading = makeViewModel().recipeList else {
            Issue.record("The recipe list did not start out reading.")
            return
        }
    }

    @Test("the recipes in the directory reach the view model")
    @MainActor
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

    @Test("a recipe added to the directory reaches the view model")
    @MainActor
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

    @Test("a directory that is gone reaches the view model as a failure")
    @MainActor
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
}
