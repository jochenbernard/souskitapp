import CookingFeature
import DesignSystem
import RecipeFeature
import RecipeLibrary
import SousKit
import SwiftUI

struct KitchenFeatureView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.scenePhase) private var scenePhase

    @ScaledMetric(relativeTo: .body) private var scaledCardWidth = Self.minimumCardWidth

    // Two columns on any iPhone; at accessibility sizes the width grows with the text, which leaves the iPhone one.
    private static let minimumCardWidth = 160.0

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
        recipeListScreen
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

    private var recipeListScreen: some View {
        ScrollView {
            // A blank page, rather than a list the restored recipe covers a moment later.
            if !viewModel.isRestoring {
                recipeList
                    .sousPagePadding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .sousPage()
        .navigationTitle(viewModel.recipeRepositoryName)
        .toolbarVisibility(viewModel.isRestoring ? .hidden : .automatic, for: .navigationBar)
        .task {
            await presenter.viewDidAppear()
        }
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

    @ViewBuilder
    private var recipeList: some View {
        switch viewModel.recipeList {
        case .reading:
            readingNote

        case .recipes(let cards):
            if cards.isEmpty {
                emptyNote
            } else {
                recipeCards(cards)
            }

        case .failure(let message):
            failureNote(message)
        }
    }

    private var readingNote: some View {
        SousActivityNote {
            Text("Reading the folder.", bundle: .module)
        }
    }

    private var emptyNote: some View {
        VStack(alignment: .leading, spacing: SousSpacing.small) {
            Text("Nothing here yet", bundle: .module)

            Text("Put .sous files in this folder and they are listed here.", bundle: .module)
                .foregroundStyle(.secondary)
        }
    }

    private func recipeCards(_ cards: [KitchenRecipeCard]) -> some View {
        RecipeCardGrid(
            minimumColumnWidth: dynamicTypeSize.isAccessibilitySize ? scaledCardWidth : Self.minimumCardWidth,
            spacing: SousSpacing.medium
        ) {
            ForEach(cards) { card in
                Button(
                    action: { presenter.didChangePushedScreen(.recipe(card.recipeEntry)) },
                    label: { RecipeCard(card) }
                )
                .buttonStyle(.plain)
            }
        }
    }

    private func failureNote(_ message: String) -> some View {
        SousFailureNote(Text("This folder could not be read", bundle: .module), message: message)
    }

    @ViewBuilder
    private func screenView(for screen: KitchenScreen) -> some View {
        switch screen {
        case .recipe(let recipeEntry):
            recipeScreen(for: recipeEntry)
        }
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

/// A card for a recipe whose header is `header`, or one not read yet where there is none.
private func previewCard(
    _ id: String,
    _ availability: RecipeAvailability,
    header: String? = nil
) -> KitchenRecipeCard {
    let parser = SousParser()

    return KitchenFeaturePresenter.card(
        for: RecipeEntry(
            id: id,
            name: id.replacing("-", with: " "),
            availability: availability,
            summary: header.map({ RecipeSummary(recipe: parser.parseRecipe($0).value, parser: parser) })
        )
    )
}

private func previewCards() -> [KitchenRecipeCard] {
    [
        previewCard(
            "boeuf-bourguignon",
            .downloaded,
            header: "---\ntitle: Boeuf Bourguignon\nprep-time: 30 min\ncook-time: 3 h\n---"
        ),
        previewCard(
            "bouillabaisse",
            .downloaded,
            header: "---\ntitle: Bouillabaisse\nprep-time: 40 min\ncook-time: 50 min\n---"
        ),
        previewCard(
            "crepes",
            .notDownloaded,
            header: "---\ntitle: Crepes\nprep-time: 10 min\ncook-time: 25 min\n---"
        ),
        previewCard(
            "gratin-dauphinois",
            .downloading,
            header: "---\ntitle: Gratin Dauphinois\nprep-time: 30 min\ncook-time: 1 h 30 min\n---"
        ),
        previewCard("steps-only", .downloaded),
        previewCard(
            "vinaigrette",
            .downloaded,
            header: "---\ntitle: Vinaigrette\nyield: [125 ml]\n---"
        )
    ]
}

#Preview("Kitchen") {
    NavigationStack {
        KitchenFeatureView(
            presenter: KitchenFeaturePresenterStub(),
            viewModel: previewViewModel(.recipes(previewCards()))
        )
    }
}

#Preview("Kitchen, largest text") {
    NavigationStack {
        KitchenFeatureView(
            presenter: KitchenFeaturePresenterStub(),
            viewModel: previewViewModel(.recipes(previewCards()))
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
            viewModel: previewViewModel(.recipes([]))
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
