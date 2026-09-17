import DesignSystem
import RecipeLibrary
import SousKit
import SwiftUI

struct RecipeFeatureView: View {
    private let presenter: RecipeFeaturePresenterProtocol
    private let viewModel: RecipeFeatureViewModel

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // The cook button's width where the screen is wide, growing with Dynamic Type.
    @ScaledMetric(relativeTo: .body) private var wideCookButtonWidth = 360.0

    init(
        presenter: RecipeFeaturePresenterProtocol,
        viewModel: RecipeFeatureViewModel
    ) {
        self.presenter = presenter
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            content
                .sousPagePadding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollEdgeEffectStyle(.soft, for: .bottom)
        .safeAreaBar(edge: .bottom) {
            cookBar
        }
        .sousPage()
        .navigationTitle(navigationTitle)
        .task {
            await presenter.viewDidAppear()
        }
    }

    private var navigationTitle: String {
        guard
            case .recipe(let recipe) = viewModel.recipeContent,
            let title = recipe.metadata.title,
            !title.isEmpty
        else {
            return viewModel.recipeEntry.name
        }

        return title
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.recipeContent {
        case .reading:
            readingNote

        case .recipe(let recipe):
            if recipe.steps.isEmpty, RecipeDisplay.metadata(of: recipe.metadata).isEmpty {
                emptyNote
            } else {
                RecipeBodyView(
                    presenter: presenter,
                    recipe: recipe,
                    expandedSections: viewModel.expandedSections
                )
            }

        case .failure(let message):
            failureNote(message)
        }
    }

    private var readingNote: some View {
        SousActivityNote {
            readingMessage
        }
    }

    private var emptyNote: some View {
        Text("This recipe is empty.", bundle: .module)
            .font(.body)
            .foregroundStyle(.secondary)
    }

    private func failureNote(_ message: String) -> some View {
        SousFailureNote(Text("This recipe could not be read", bundle: .module), message: message)
    }

    @ViewBuilder
    private var readingMessage: some View {
        if viewModel.recipeEntry.availability == .downloaded {
            Text("Reading the recipe.", bundle: .module)
        } else {
            Text("Fetching from iCloud.", bundle: .module)
        }
    }

    @ViewBuilder
    private var cookBar: some View {
        if case .recipe(let recipe) = viewModel.recipeContent, !recipe.steps.isEmpty {
            cookButton
        }
    }

    private var cookButton: some View {
        Button(action: presenter.didTapCook) {
            Text("Start cooking", bundle: .module)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.sousPrimary)
        .frame(maxWidth: horizontalSizeClass == .regular ? wideCookButtonWidth : .infinity)
        .sousPagePadding()
    }
}

private func previewRecipeEntry(_ availability: RecipeAvailability) -> RecipeEntry {
    RecipeEntry(
        id: "boeuf-bourguignon",
        name: "boeuf bourguignon",
        availability: availability
    )
}

@MainActor
private func previewViewModel(_ recipeContent: RecipeContent) -> RecipeFeatureViewModel {
    let viewModel = RecipeFeatureViewModel(recipeEntry: previewRecipeEntry(.downloaded))
    viewModel.recipeContent = recipeContent

    return viewModel
}

private func previewRecipe() -> Recipe {
    SousParser().parseRecipe(
        """
        ---
        title: Boeuf Bourguignon
        servings: 6
        prep-time: 30 min
        cook-time: 3 h
        tags: [dinner, classic, french]
        allergens: [gluten, dairy]
        ---

        Cut @{1.2 kg} beef@ into large cubes and pat them dry. Brown @{150 g} lardons@ in a
        #casserole# for ~5 min~ until the fat runs, lift them out, then brown the beef in
        batches in the rendered fat over high heat.

        Cover the pot and braise at 150C for ~3 h~, until the beef gives to a fork.
        """
    )
    .value
}

#Preview("Recipe") {
    NavigationStack {
        RecipeFeatureView(
            presenter: RecipeFeaturePresenterStub(),
            viewModel: previewViewModel(.recipe(previewRecipe()))
        )
    }
}

#Preview("Recipe, fetching from iCloud") {
    NavigationStack {
        RecipeFeatureView(
            presenter: RecipeFeaturePresenterStub(),
            viewModel: RecipeFeatureViewModel(recipeEntry: previewRecipeEntry(.notDownloaded))
        )
    }
}

#Preview("Recipe, after a failure") {
    NavigationStack {
        RecipeFeatureView(
            presenter: RecipeFeaturePresenterStub(),
            viewModel: previewViewModel(.failure("The recipe no longer exists."))
        )
    }
}
