import Foundation
@testable import KitchenFeature
import Observation
import os
import RecipeLibrary
import SousKit
import Testing

@Suite("Kitchen feature documents", .timeLimit(.minutes(1)))
struct KitchenFeatureDocumentTests {
    let parser = SousParser()
    let crepesURL = URL(filePath: "/Recipes/crepes.sous")
    let vinaigretteURL = URL(filePath: "/Downloads/vinaigrette.sous")

    func recipeEntry(_ id: String) -> RecipeEntry {
        RecipeEntry(
            id: id,
            name: id,
            availability: .downloaded
        )
    }

    @MainActor
    func document(at url: URL) -> RecipeDocument {
        RecipeDocument(
            url: url,
            entry: recipeEntry(url.absoluteString),
            recipeRepository: RecipeRepositorySpy()
        )
    }

    /// A presenter whose repository holds `crepes.sous` and lists the given recipes once its stack appears.
    @MainActor
    func makePresenter(
        viewModel: KitchenFeatureViewModel,
        listing recipeEntries: [RecipeEntry],
        handler: KitchenFeatureHandlerStub = KitchenFeatureHandlerStub()
    ) async -> KitchenFeaturePresenter {
        let recipeRepository = RecipeRepositorySpy(fileIDs: [crepesURL: "crepes.sous"])
        let presenter = KitchenFeaturePresenter.stubbed(
            viewModel: viewModel,
            parser: parser,
            handler: handler,
            recipeRepository: recipeRepository
        )
        recipeRepository.send(.success(recipeEntries))
        recipeRepository.finish()
        await presenter.stackDidAppear()

        return presenter
    }

    @MainActor
    @Test("a file the repository lists opens as its recipe, in place of what was pushed")
    func listedFileOpensItsRecipe() async {
        let crepes = recipeEntry("crepes.sous")
        let viewModel = KitchenFeatureViewModel(recipeRepositoryName: "Recipes")
        let presenter = await makePresenter(viewModel: viewModel, listing: [crepes])
        presenter.screenDidAppear(nil)
        presenter.didPush(.folder(["Baking"]), from: nil)

        presenter.didOpen(document(at: crepesURL))

        #expect(viewModel.pushedScreens == [.recipe(crepes)])
        #expect(viewModel.openRecipe?.recipeEntry == crepes)
    }

    @MainActor
    @Test("a file outside the repository opens where it sits, and is not opened again on a cold start")
    func outsideFileOpensAsDocument() async {
        let vinaigrette = document(at: vinaigretteURL)
        let viewModel = KitchenFeatureViewModel(recipeRepositoryName: "Recipes")
        let handler = KitchenFeatureHandlerStub()
        let presenter = await makePresenter(
            viewModel: viewModel,
            listing: [],
            handler: handler
        )
        presenter.screenDidAppear(nil)

        presenter.didOpen(vinaigrette)

        #expect(viewModel.pushedScreens == [.document(vinaigrette.entry)])
        #expect(viewModel.openRecipe?.recipeEntry == vinaigrette.entry)
        #expect(handler.restoration == nil)
    }

    @MainActor
    @Test("a file the repository holds but does not list opens where it sits")
    func unlistedFileOpensAsDocument() async {
        let crepes = document(at: crepesURL)
        let viewModel = KitchenFeatureViewModel(recipeRepositoryName: "Recipes")
        let presenter = await makePresenter(viewModel: viewModel, listing: [recipeEntry("brioche.sous")])
        presenter.screenDidAppear(nil)

        presenter.didOpen(crepes)

        #expect(viewModel.pushedScreens == [.document(crepes.entry)])
    }

    @MainActor
    @Test("a file waits for the kitchen's own screen, and for the listing, before it opens")
    func fileWaitsForTheKitchen() async {
        let crepes = recipeEntry("crepes.sous")
        let viewModel = KitchenFeatureViewModel(recipeRepositoryName: "Recipes")
        let recipeRepository = RecipeRepositorySpy(fileIDs: [crepesURL: "crepes.sous"])
        let presenter = KitchenFeaturePresenter.stubbed(
            viewModel: viewModel,
            parser: parser,
            recipeRepository: recipeRepository
        )

        presenter.didOpen(document(at: crepesURL))
        presenter.screenDidAppear(nil)
        #expect(viewModel.pushedScreens.isEmpty)

        recipeRepository.send(.success([crepes]))
        recipeRepository.finish()
        await presenter.stackDidAppear()

        #expect(viewModel.pushedScreens == [.recipe(crepes)])
    }

    @MainActor
    @Test("a file takes the place of what a cold start was opening again")
    func fileEndsTheRestoration() {
        let vinaigrette = document(at: vinaigretteURL)
        let viewModel = KitchenFeatureViewModel(recipeRepositoryName: "Recipes")
        viewModel.isRestoring = true
        let handler = KitchenFeatureHandlerStub()
        let presenter = KitchenFeaturePresenter.stubbed(
            viewModel: viewModel,
            parser: parser,
            handler: handler,
            restoration: KitchenFeatureRestoration(recipeID: "brioche.sous")
        )

        presenter.didOpen(vinaigrette)
        presenter.screenDidAppear(nil)

        #expect(!viewModel.isRestoring)
        #expect(handler.restoreCount == 1)
        #expect(viewModel.pushedScreens == [.document(vinaigrette.entry)])
    }

    @MainActor
    @Test("the recipe already on top stays as it is when its file is opened again")
    func sameFileKeepsTheRecipe() async {
        let vinaigrette = document(at: vinaigretteURL)
        let viewModel = KitchenFeatureViewModel(recipeRepositoryName: "Recipes")
        let presenter = await makePresenter(viewModel: viewModel, listing: [])
        presenter.screenDidAppear(nil)
        presenter.didOpen(vinaigrette)
        let isReplaced = OSAllocatedUnfairLock(initialState: false)
        withObservationTracking(
            { _ = viewModel.openRecipe },
            onChange: { isReplaced.withLock({ $0 = true }) }
        )

        presenter.didOpen(document(at: vinaigretteURL))
        let isFeatureReplaced = isReplaced.withLock({ $0 })

        #expect(viewModel.pushedScreens == [.document(vinaigrette.entry)])
        #expect(!isFeatureReplaced)
    }

    @MainActor
    @Test("a file opened while cooking is open opens nothing, then or after")
    func fileWhileCookingOpensNothing() async {
        let crepes = recipeEntry("crepes.sous")
        let viewModel = KitchenFeatureViewModel(recipeRepositoryName: "Recipes")
        let presenter = await makePresenter(viewModel: viewModel, listing: [crepes])
        presenter.screenDidAppear(nil)
        presenter.didPush(.recipe(crepes), from: nil)
        presenter.recipeFeatureDidStartCooking(recipe: parser.parseRecipe("Whisk it.").value)

        presenter.didOpen(document(at: vinaigretteURL))
        presenter.cookingFeatureDidExit()
        presenter.screenDidAppear(nil)

        #expect(viewModel.pushedScreens == [.recipe(crepes)])
    }
}
