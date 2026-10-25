import DesignSystem
import RecipeFeature
import RecipeLibrary
import SwiftUI

/// A glance at the recipe a card opens, as the presenter built it for the glance.
struct RecipeCardPreview: View {
    private let card: KitchenRecipeCard
    private let presenter: KitchenFeaturePresenterProtocol
    private let viewModel: KitchenFeatureViewModel
    private let maximumHeight: CGFloat

    /// - Parameter maximumHeight: The most height the glance may take.
    init(
        _ card: KitchenRecipeCard,
        presenter: KitchenFeaturePresenterProtocol,
        viewModel: KitchenFeatureViewModel,
        maximumHeight: CGFloat
    ) {
        self.card = card
        self.presenter = presenter
        self.viewModel = viewModel
        self.maximumHeight = maximumHeight
    }

    var body: some View {
        if let previewedRecipe = viewModel.previewedRecipe, previewedRecipe.recipeEntry == card.recipeEntry {
            previewedRecipe.feature.makePreview(
                placeholder: RecipePlaceholder(
                    symbol: viewModel.symbols[card.id],
                    color: card.placeholderColor
                ),
                maximumHeight: maximumHeight
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
        viewModel: KitchenFeatureViewModel(recipeRepositoryName: "Recipes"),
        maximumHeight: 544.0
    )
    .frame(width: 370.0)
    .fixedSize(horizontal: false, vertical: true)
}
