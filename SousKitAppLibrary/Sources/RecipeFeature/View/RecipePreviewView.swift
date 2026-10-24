import DesignSystem
import RecipeLibrary
import SousKit
import SwiftUI

/// A glance at a recipe before it is opened: its header on the card the screen opens with, without the scale, which
/// is something to do on the screen rather than something to read.
struct RecipePreviewView: View {
    @LineContainerRadius private var radius

    private let presenter: RecipeFeaturePresenterProtocol
    private let viewModel: RecipeFeatureViewModel
    private let placeholder: RecipePlaceholder

    init(
        presenter: RecipeFeaturePresenterProtocol,
        viewModel: RecipeFeatureViewModel,
        placeholder: RecipePlaceholder
    ) {
        self.presenter = presenter
        self.viewModel = viewModel
        self.placeholder = placeholder
    }

    var body: some View {
        card
            .task {
                await presenter.viewDidAppear()
            }
    }

    @ViewBuilder
    private var card: some View {
        switch viewModel.recipeContent {
        case .recipe(let recipe):
            RecipeMetadataView(
                presenter: presenter,
                metadata: RecipeDisplay.metadata(of: recipe.scaled.metadata),
                scale: nil,
                header: header
            )

        case .reading, .failure:
            header
                .clipShape(.rect(cornerRadius: radius))
                .sousRowSurface()
        }
    }

    private var header: RecipeHeaderView {
        RecipeHeaderView(
            presenter: presenter,
            viewModel: viewModel,
            placeholder: placeholder,
            title: viewModel.title,
            placement: .card,
            barBottom: 0.0,
            // A glance has no bar for the title to scroll under.
            isTitleUnderBar: .constant(false)
        )
    }
}

@MainActor
private func previewViewModel(_ recipeContent: RecipeContent) -> RecipeFeatureViewModel {
    let viewModel = RecipeFeatureViewModel(
        recipeEntry: RecipeEntry(
            id: "boeuf-bourguignon",
            name: "boeuf bourguignon",
            availability: .downloaded
        ),
        folderPath: ["Recipes", "French", "Classic"]
    )
    viewModel.recipeContent = recipeContent

    return viewModel
}

private func previewRecipe() -> ScaledRecipe {
    let parser = SousParser()
    let recipe = parser.parseRecipe(
        """
        ---
        title: Boeuf Bourguignon
        servings: 6
        prep-time: 30 min
        cook-time: 3 h
        tags: [dinner, classic, french]
        allergens: [gluten, dairy]
        ---

        Cut @{1.2 kg} beef@ into large cubes and pat them dry.
        """
    )
    .value

    return ScaledRecipe(asWritten: recipe, parser: parser)
}

#Preview("Recipe preview") {
    RecipePreviewView(
        presenter: RecipeFeaturePresenterStub(),
        viewModel: previewViewModel(.recipe(previewRecipe())),
        placeholder: RecipePlaceholder(symbol: "fork.knife", color: .pink)
    )
    .frame(width: 370.0)
    .fixedSize(horizontal: false, vertical: true)
    .sousPage()
}

#Preview("Recipe preview, reading") {
    RecipePreviewView(
        presenter: RecipeFeaturePresenterStub(),
        viewModel: previewViewModel(.reading),
        placeholder: RecipePlaceholder(symbol: "fork.knife", color: .pink)
    )
    .frame(width: 370.0)
    .fixedSize(horizontal: false, vertical: true)
    .sousPage()
}
