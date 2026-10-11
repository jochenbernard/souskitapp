import Foundation
import RecipeLibrary
import RecipeScaling
@testable import SettingsFeature
import Testing

@MainActor
@Suite("Settings feature presenter")
struct SettingsFeaturePresenterTests {
    private let handler = SettingsFeatureHandlerSpy()

    private func makeViewModel(_ preferredScale: PreferredScale = .asWritten) -> SettingsFeatureViewModel {
        SettingsFeatureViewModel(
            recipeRepositoryName: "Recipes",
            recipeRepositoryKind: .files,
            appVersion: AppVersion(version: "0.3", build: "4"),
            scale: RecipeScale(preferredScale)
        )
    }

    private func makePresenter(
        viewModel: SettingsFeatureViewModel,
        preferredScaleStore: PreferredScaleStore = PreferredScaleStoreSpy(),
        recipeRepositoryStore: RecipeRepositoryStore = RecipeRepositoryStoreSpy()
    ) -> SettingsFeaturePresenter {
        SettingsFeaturePresenter(
            handler: handler,
            preferredScaleStore: preferredScaleStore,
            recipeRepositoryStore: recipeRepositoryStore,
            viewModel: viewModel
        )
    }

    @Test("Done reports the settings finished")
    func done() {
        makePresenter(viewModel: makeViewModel()).didTapDone()

        #expect(handler.finishCount == 1)
    }

    @Test("a folder picked is recorded, then reported")
    func folderPicked() {
        let store = RecipeRepositoryStoreSpy()
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel, recipeRepositoryStore: store)
        let url = URL(filePath: "/Recipes/brioche")

        presenter.didTapChangeDirectory()
        #expect(viewModel.isChoosingDirectory)

        presenter.didChooseDirectory(.success(url))

        #expect(store.connectedURLs == [url])
        #expect(handler.connectedRecipeRepositoryNames == ["brioche"])
        #expect(viewModel.failureMessage == nil)
    }

    @Test("a folder that cannot be recorded stays on the settings with the failure")
    func folderFailing() {
        let viewModel = makeViewModel()
        let presenter = makePresenter(
            viewModel: viewModel,
            recipeRepositoryStore: RecipeRepositoryStoreSpy(fails: true)
        )

        presenter.didChooseDirectory(.success(URL(filePath: "/Recipes")))

        #expect(viewModel.failureMessage != nil)
        #expect(handler.connectedRecipeRepositoryNames.isEmpty)

        presenter.didTapChangeDirectory()

        #expect(viewModel.failureMessage == nil)
    }

    @Test("a picker that fails reports nothing")
    func pickerFailing() {
        let viewModel = makeViewModel()

        makePresenter(viewModel: viewModel).didChooseDirectory(.failure(CocoaError(.userCancelled)))

        #expect(viewModel.failureMessage != nil)
        #expect(handler.connectedRecipeRepositoryNames.isEmpty)
    }

    @Test("the scale sheet opens on the scale in force")
    func scaleSheetOpens() {
        let viewModel = makeViewModel(.servings(6.0))

        makePresenter(viewModel: viewModel).didTapScale()

        #expect(viewModel.isScaling)
        #expect(viewModel.scaleText == "6")
    }

    @Test("switching to servings or the multiplier starts each on its own number and remembers it")
    func switchingTargets() {
        let store = PreferredScaleStoreSpy()
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel, preferredScaleStore: store)

        presenter.didTapTarget(.servings)

        #expect(viewModel.scale == RecipeScale(target: .servings, value: 4.0))
        #expect(viewModel.scaleText == "4")
        #expect(store.preferredScale == .servings(4.0))

        presenter.didTapTarget(.multiplier)

        #expect(viewModel.scale == RecipeScale(target: .multiplier, value: 1.0))
        #expect(store.preferredScale == .asWritten)
    }

    @Test("switching to the target already chosen keeps its number")
    func switchingToTheSameTarget() {
        let store = PreferredScaleStoreSpy(.servings(6.0))
        let viewModel = makeViewModel(.servings(6.0))

        makePresenter(viewModel: viewModel, preferredScaleStore: store).didTapTarget(.servings)

        #expect(viewModel.scale == RecipeScale(target: .servings, value: 6.0))
        #expect(store.preferredScale == .servings(6.0))
    }

    @Test(
        "the minus and the plus step the number within its range",
        arguments: [
            (PreferredScale.servings(4.0), 1.0, PreferredScale.servings(5.0)),
            (.servings(4.0), -1.0, .servings(3.0)),
            (.servings(1.0), -1.0, .servings(1.0)),
            (.multiplier(1.0), 1.0, .multiplier(1.5)),
            (.multiplier(1.0), -1.0, .multiplier(0.5)),
            (.multiplier(0.5), -1.0, .multiplier(0.5))
        ]
    )
    func stepping(
        from start: PreferredScale,
        steps: Double,
        to end: PreferredScale
    ) {
        let store = PreferredScaleStoreSpy(start)
        let viewModel = makeViewModel(start)

        makePresenter(viewModel: viewModel, preferredScaleStore: store).didStepScale(by: steps)

        #expect(viewModel.scale == RecipeScale(end))
        #expect(viewModel.scaleText == ScaleNumber.text(RecipeScale(end).value))
        #expect(store.preferredScale == end)
    }

    @Test("a number typed moves the scale and leaves the field as it is typed")
    func typing() {
        let store = PreferredScaleStoreSpy()
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel, preferredScaleStore: store)

        presenter.didChangeScaleText("2.")

        #expect(viewModel.scaleText == "2.")
        #expect(store.preferredScale == .multiplier(2.0))

        presenter.didChangeScaleText("")

        #expect(store.preferredScale == .multiplier(2.0))

        presenter.didChangeIsScaling(false)

        #expect(viewModel.scaleText == "2")
    }

    @Test("a number too small to keep leaves the scale where it is")
    func typingTooSmall() {
        let store = PreferredScaleStoreSpy(.multiplier(2.0))
        let viewModel = makeViewModel(.multiplier(2.0))
        let presenter = makePresenter(viewModel: viewModel, preferredScaleStore: store)

        presenter.didChangeScaleText("0.0000001")

        #expect(viewModel.scale == RecipeScale(target: .multiplier, value: 2.0))
        #expect(store.preferredScale == .multiplier(2.0))
    }

    @Test("reset goes back to the recipe as written")
    func resetScale() {
        let store = PreferredScaleStoreSpy(.servings(6.0))
        let viewModel = makeViewModel(.servings(6.0))

        makePresenter(viewModel: viewModel, preferredScaleStore: store).didTapReset()

        #expect(viewModel.scale == RecipeScale(target: .multiplier, value: 1.0))
        #expect(viewModel.scaleText == "1")
        #expect(store.preferredScale == .asWritten)
    }

    @Test("the sheet shows servings and the multiplier, and offers no reset at 1×")
    func display() {
        let atDefault = ScaleDisplay(preferred: RecipeScale(.asWritten), text: "1")
        let onServings = ScaleDisplay(preferred: RecipeScale(.servings(4.0)), text: "4")

        #expect(atDefault.targets == [.servings, .multiplier])
        #expect(atDefault.follows.isEmpty)
        #expect(atDefault.isDefault)
        #expect(!onServings.isDefault)
    }

    @Test("picking another kind of repository moves the switch and reports it, leaving the folder in force")
    func kindPicked() {
        let viewModel = makeViewModel()

        makePresenter(viewModel: viewModel).didSelectRecipeRepositoryKind(.mock)

        #expect(viewModel.selectedRecipeRepositoryKind == .mock)
        #expect(viewModel.recipeRepositoryKind == .files)
        #expect(handler.selectedRecipeRepositoryKinds == [.mock])
    }

    @Test("a reset is confirmed before it is reported")
    func reset() {
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didTapResetApp()

        #expect(viewModel.isConfirmingReset)
        #expect(handler.resetCount == 0)

        presenter.didConfirmReset()

        #expect(!viewModel.isConfirmingReset)
        #expect(handler.resetCount == 1)
    }

    @Test("a reset dismissed reports nothing")
    func resetDismissed() {
        let viewModel = makeViewModel()
        let presenter = makePresenter(viewModel: viewModel)

        presenter.didTapResetApp()
        presenter.didChangeIsConfirmingReset(false)

        #expect(!viewModel.isConfirmingReset)
        #expect(handler.resetCount == 0)
    }
}
