import DesignSystem
import RecipeFeature
import RecipeLibrary
import SwiftUI

/// A glance at the recipe a card opens, which the presenter reads for the glance as it appears.
struct RecipeCardPreview: View {
    private let card: KitchenRecipeCard
    private let presenter: KitchenFeaturePresenterProtocol
    private let viewModel: KitchenFeatureViewModel

    init(
        _ card: KitchenRecipeCard,
        presenter: KitchenFeaturePresenterProtocol,
        viewModel: KitchenFeatureViewModel
    ) {
        self.card = card
        self.presenter = presenter
        self.viewModel = viewModel
    }

    var body: some View {
        content
            .onAppear {
                presenter.didPreview(card.recipeEntry)
            }
    }

    @ViewBuilder
    private var content: some View {
        if let previewedRecipe = viewModel.previewedRecipe, previewedRecipe.recipeEntry == card.recipeEntry {
            previewedRecipe.feature.makePreview(
                placeholder: RecipePlaceholder(
                    symbol: viewModel.symbols[card.id],
                    color: card.placeholderColor
                )
            )
        } else {
            // The card stands in for the moment the recipe's own preview takes to be built.
            RecipeCard(
                card,
                thumbnails: viewModel.thumbnails,
                symbols: viewModel.symbols,
                presenter: presenter
            )
        }
    }
}

#Preview("Recipe card preview, before it is read") {
    RecipeCardPreview(
        KitchenRecipeCard(
            recipeEntry: RecipeEntry(
                id: "brioche",
                name: "brioche",
                availability: .downloaded
            )
        ),
        presenter: KitchenFeaturePresenterStub(),
        viewModel: KitchenFeatureViewModel(recipeRepositoryName: "Recipes")
    )
    .frame(width: 370.0)
    .fixedSize(horizontal: false, vertical: true)
}
