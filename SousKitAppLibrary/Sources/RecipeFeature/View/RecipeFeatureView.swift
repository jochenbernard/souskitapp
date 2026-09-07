import DesignSystem
import Foundation
import RecipeLibrary
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
                .padding(SousSpacing.xLarge)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .sousPage()
        .navigationTitle(viewModel.recipeFile.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await presenter.viewDidAppear()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.recipeText {
        case .reading:
            readingNote

        case .text(let text):
            if text.isEmpty {
                emptyNote
            } else {
                recipeSource(text)
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
        Text("This recipe is empty.")
            .sousTextStyle(.body)
            .foregroundStyle(SousColor.textMuted)
    }

    private func recipeSource(_ text: String) -> some View {
        Text(verbatim: text)
            .sousTextStyle(.data)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func failureNote(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: SousSpacing.small) {
            Text("This recipe could not be read")
                .sousTextStyle(.body)

            Text(verbatim: message)
                .sousTextStyle(.body)
        }
        .sousCallout()
    }

    @ViewBuilder
    private var readingMessage: some View {
        if viewModel.recipeFile.availability == .downloaded {
            Text("Reading the recipe.")
                .sousTextStyle(.body)
        } else {
            Text("Fetching from iCloud.")
                .sousTextStyle(.body)
        }
    }
}

private func previewRecipeFile(_ availability: RecipeFileAvailability) -> RecipeFile {
    RecipeFile(
        url: URL(filePath: "/Users/cook/Recipes/boeuf-bourguignon.sous"),
        availability: availability
    )
}

@MainActor
private func previewViewModel(_ recipeText: RecipeText) -> RecipeFeatureViewModel {
    let viewModel = RecipeFeatureViewModel(recipeFile: previewRecipeFile(.downloaded))
    viewModel.recipeText = recipeText

    return viewModel
}

#Preview("Recipe") {
    NavigationStack {
        RecipeFeatureView(
            presenter: RecipeFeaturePresenterStub(),
            viewModel: previewViewModel(
                .text(
                    """
                    ---
                    title: Boeuf Bourguignon
                    servings: 6
                    prep-time: 30 min
                    cook-time: 3 h
                    ---

                    Cut @{1.2 kg} beef@ into large cubes and pat them dry. Brown
                    @{150 g} lardons@ in a #casserole# for ~5 min~ until the fat runs.

                    Cover the pot and braise at 150C for ~3 h~, until the beef gives to
                    a fork.
                    """
                )
            )
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
