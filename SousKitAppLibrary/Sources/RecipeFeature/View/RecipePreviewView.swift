import DesignSystem
import RecipeLibrary
import SousKit
import SwiftUI

/// A glance at a recipe before it is opened: the card the screen opens with, cut to its picture, title, facts and
/// tags, so it fits the room a preview has.
struct RecipePreviewView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // A preview cannot scroll, and past this size the facts alone outgrow it.
    private static let largestTypeSize = DynamicTypeSize.accessibility1
    // Two rows of tags, or one at accessibility sizes, where two outgrow an iPad's preview.
    private static let maximumTagRowCount = 2

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
        RecipeMetadataView(
            presenter: presenter,
            metadata: metadata,
            scale: nil,
            header: header,
            tagRowCount: tagRowCount
        )
        .dynamicTypeSize(...Self.largestTypeSize)
        .task {
            await presenter.viewDidAppear()
        }
    }

    private var metadata: MetadataDisplay {
        switch viewModel.recipeContent {
        case .recipe(let recipe):
            RecipeDisplay.metadata(of: recipe.scaled.metadata).glance

        case .reading, .failure:
            MetadataDisplay(
                facts: [],
                tags: [],
                allergens: [],
                rows: []
            )
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

    private var tagRowCount: Int {
        dynamicTypeSize.isAccessibilitySize ? 1 : Self.maximumTagRowCount
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

private func previewRecipe(
    _ text: String = """
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
) -> ScaledRecipe {
    let parser = SousParser()
    let recipe = parser.parseRecipe(text).value

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

#Preview("Recipe preview, header of nothing but a title") {
    RecipePreviewView(
        presenter: RecipeFeaturePresenterStub(),
        viewModel: previewViewModel(
            .recipe(
                previewRecipe(
                    """
                    ---
                    title: Vinaigrette
                    ---
                    """
                )
            )
        ),
        placeholder: RecipePlaceholder(symbol: "fork.knife", color: .pink)
    )
    .frame(width: 370.0)
    .fixedSize(horizontal: false, vertical: true)
    .sousPage()
}

#Preview("Recipe preview, many tags") {
    RecipePreviewView(
        presenter: RecipeFeaturePresenterStub(),
        viewModel: previewViewModel(
            .recipe(
                previewRecipe(
                    """
                    ---
                    title: Ratatouille
                    servings: 4
                    prep-time: 25 min
                    cook-time: 1 h 15 min
                    tags: [dinner, lunch, vegetarian, vegan, summer, provencal, french, classic, make-ahead, picnic]
                    ---
                    """
                )
            )
        ),
        placeholder: RecipePlaceholder(symbol: "fork.knife", color: .pink)
    )
    .frame(width: 320.0)
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
