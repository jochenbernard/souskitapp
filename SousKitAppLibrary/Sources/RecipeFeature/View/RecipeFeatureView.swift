import DesignSystem
import Foundation
import RecipeLibrary
import SousKit
import SwiftUI

struct RecipeFeatureView: View {
    private let presenter: RecipeFeaturePresenterProtocol
    private let viewModel: RecipeFeatureViewModel

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
                .padding(.horizontal, SousSpacing.large)
                .padding(.vertical, SousSpacing.small)
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

    /// The recipe's own title once it is read, and the file's name until then.
    private var navigationTitle: String {
        guard
            case .recipe(let recipe) = viewModel.recipeContent,
            let title = recipe.metadata.title
        else {
            return viewModel.recipeFile.name
        }

        return title
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.recipeContent {
        case .reading:
            readingNote

        case .recipe(let recipe):
            if recipe.groups.isEmpty, recipe.metadata.entries.isEmpty {
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
                .font(.body)
        }
    }

    private var emptyNote: some View {
        Text("This recipe is empty.")
            .font(.body)
            .foregroundStyle(.secondary)
    }

    private func failureNote(_ message: String) -> some View {
        SousFailureNote(Text("This recipe could not be read"), message: message)
    }

    @ViewBuilder
    private var readingMessage: some View {
        if viewModel.recipeFile.availability == .downloaded {
            Text("Reading the recipe.")
        } else {
            Text("Fetching from iCloud.")
        }
    }

    /// The cook button, shown once the recipe is read and only where there is something to cook.
    @ViewBuilder
    private var cookBar: some View {
        if case .recipe(let recipe) = viewModel.recipeContent, !recipe.steps.isEmpty {
            cookButton
        }
    }

    private var cookButton: some View {
        Button(action: presenter.didTapCook) {
            Text("Start cooking")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.sousPrimary)
        .padding(.horizontal, SousSpacing.large)
        .padding(.vertical, SousSpacing.small)
    }
}

private func previewRecipeFile(_ availability: RecipeFileAvailability) -> RecipeFile {
    RecipeFile(
        url: URL(filePath: "/Users/cook/Recipes/boeuf-bourguignon.sous"),
        availability: availability
    )
}

@MainActor
private func previewViewModel(_ recipeContent: RecipeContent) -> RecipeFeatureViewModel {
    let viewModel = RecipeFeatureViewModel(recipeFile: previewRecipeFile(.downloaded))
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
            viewModel: RecipeFeatureViewModel(recipeFile: previewRecipeFile(.notDownloaded))
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
