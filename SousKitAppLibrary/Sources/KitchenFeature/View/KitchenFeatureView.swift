import CookingFeature
import DesignSystem
import RecipeFeature
import RecipeLibrary
import SousKit
import SwiftUI

struct KitchenFeatureView: View {
    @Environment(\.scenePhase) private var scenePhase

    @Namespace private var cookingTransition

    private let presenter: KitchenFeaturePresenterProtocol
    private let viewModel: KitchenFeatureViewModel

    init(
        presenter: KitchenFeaturePresenterProtocol,
        viewModel: KitchenFeatureViewModel
    ) {
        self.presenter = presenter
        self.viewModel = viewModel
    }

    var body: some View {
        topScreen
            .navigationDestination(for: KitchenScreen.self) { screen in
                screenView(for: screen)
            }
            // Over the whole kitchen rather than pushed on it, zooming out of the button that starts it, and never
            // swiped or pinched away: its own exit is the only way out.
            .fullScreenCover(item: openCooking) { openCooking in
                openCooking.feature.makeView()
                    .navigationTransition(.zoom(sourceID: RecipeFeature.cookingTransitionID, in: cookingTransition))
                    .interactiveDismissDisabled()
                    .background {
                        InteractiveDismissRefusal()
                    }
            }
            // Cooking a cold start opens again is there at once, rather than zooming out of a button it never left.
            .transaction(value: viewModel.openCooking?.id) { transaction in
                if viewModel.openCooking?.isResumed == true {
                    transaction.disablesAnimations = true
                }
            }
    }

    private var topScreen: some View {
        folderPage(at: [])
            .navigationTitle(viewModel.recipeRepositoryName)
            .searchable(text: searchText, prompt: Text("Search recipes", bundle: .module))
            .toolbarVisibility(viewModel.isRestoring ? .hidden : .automatic, for: .navigationBar)
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .active:
                    Task {
                        await presenter.didBecomeActive()
                    }

                case .background, .inactive:
                    break

                @unknown default:
                    break
                }
            }
    }

    private func folderPage(at path: [String]) -> some View {
        KitchenFolderPage(
            path: path,
            presenter: presenter,
            viewModel: viewModel
        )
    }

    private var searchText: Binding<String> {
        Binding(
            get: { viewModel.searchText },
            set: { text in presenter.didChangeSearchText(text) }
        )
    }

    @ViewBuilder
    private func screenView(for screen: KitchenScreen) -> some View {
        switch screen {
        case .folder(let path):
            folderScreen(at: path)

        case .recipe(let recipeEntry):
            recipeScreen(for: recipeEntry)
        }
    }

    private func folderScreen(at path: [String]) -> some View {
        folderPage(at: path)
            .navigationTitle(path.last ?? "")
    }

    @ViewBuilder
    private func recipeScreen(for recipeEntry: RecipeEntry) -> some View {
        if let openRecipe = viewModel.openRecipe, openRecipe.recipeEntry == recipeEntry {
            openRecipe.feature.makeView(cookingTransition: cookingTransition)
        }
    }

    private var openCooking: Binding<OpenCooking?> {
        Binding(
            get: { viewModel.openCooking },
            set: { openCooking in
                if openCooking == nil {
                    presenter.didDismissCooking()
                }
            }
        )
    }
}

@MainActor
private func previewViewModel(
    _ recipeList: KitchenRecipeList,
    isRestoring: Bool = false
) -> KitchenFeatureViewModel {
    let viewModel = KitchenFeatureViewModel(recipeRepositoryName: "Recipes")
    viewModel.recipeList = recipeList
    viewModel.isRestoring = isRestoring

    return viewModel
}

/// A recipe whose header is `header`, or one not read yet where there is none.
private func previewEntry(
    _ path: String,
    _ availability: RecipeAvailability,
    header: String? = nil
) -> RecipeEntry {
    let parser = SousParser()
    let components = path.split(separator: "/").map(String.init)

    return RecipeEntry(
        id: path,
        name: (components.last ?? path).replacing("-", with: " "),
        availability: availability,
        summary: header.map({ RecipeSummary(recipe: parser.parseRecipe($0).value, parser: parser) }),
        folderPath: Array(components.dropLast())
    )
}

private func previewFolder() -> KitchenFolder {
    KitchenFolderTree.folder(
        at: [],
        holding: [
            previewEntry(
                "boeuf-bourguignon",
                .downloaded,
                header: "---\ntitle: Boeuf Bourguignon\nprep-time: 30 min\ncook-time: 3 h\n---"
            ),
            previewEntry(
                "Dinner/Provencal/bouillabaisse",
                .downloaded,
                header: "---\ntitle: Bouillabaisse\nprep-time: 40 min\ncook-time: 50 min\n---"
            ),
            previewEntry(
                "Baking/crepes",
                .notDownloaded,
                header: "---\ntitle: Crepes\nprep-time: 10 min\ncook-time: 25 min\n---"
            ),
            previewEntry(
                "Baking/brioche",
                .downloaded,
                header: "---\ntitle: Brioche\nprep-time: 40 min\ncook-time: 55 min\n---"
            ),
            previewEntry(
                "gratin-dauphinois",
                .downloading,
                header: "---\ntitle: Gratin Dauphinois\nprep-time: 30 min\ncook-time: 1 h 30 min\n---"
            ),
            previewEntry("steps-only", .downloaded),
            previewEntry(
                "vinaigrette",
                .downloaded,
                header: "---\ntitle: Vinaigrette\nyield: [125 ml]\n---"
            )
        ]
    )
}

#Preview("Kitchen") {
    NavigationStack {
        KitchenFeatureView(
            presenter: KitchenFeaturePresenterStub(),
            viewModel: previewViewModel(.recipes(previewFolder()))
        )
    }
}

#Preview("Kitchen, inside a folder") {
    let viewModel = previewViewModel(.recipes(previewFolder()))
    viewModel.pushedScreens = [.folder(["Baking"])]

    return NavigationStack(path: .constant(NavigationPath(viewModel.pushedScreens))) {
        KitchenFeatureView(
            presenter: KitchenFeaturePresenterStub(),
            viewModel: viewModel
        )
    }
}

#Preview("Kitchen, largest text") {
    NavigationStack {
        KitchenFeatureView(
            presenter: KitchenFeaturePresenterStub(),
            viewModel: previewViewModel(.recipes(previewFolder()))
        )
    }
    .dynamicTypeSize(.accessibility5)
}

#Preview("Kitchen, reading") {
    NavigationStack {
        KitchenFeatureView(
            presenter: KitchenFeaturePresenterStub(),
            viewModel: previewViewModel(.reading)
        )
    }
}

#Preview("Kitchen, restoring") {
    NavigationStack {
        KitchenFeatureView(
            presenter: KitchenFeaturePresenterStub(),
            viewModel: previewViewModel(.reading, isRestoring: true)
        )
    }
}

#Preview("Kitchen, empty") {
    NavigationStack {
        KitchenFeatureView(
            presenter: KitchenFeaturePresenterStub(),
            viewModel: previewViewModel(.recipes(KitchenFolderTree.folder(at: [], holding: [])))
        )
    }
}

#Preview("Kitchen, after a failure") {
    NavigationStack {
        KitchenFeatureView(
            presenter: KitchenFeaturePresenterStub(),
            viewModel: previewViewModel(.failure("The folder no longer exists."))
        )
    }
}
