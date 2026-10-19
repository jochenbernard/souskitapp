import DesignSystem
import RecipeLibrary
import SousKit
import SwiftUI

/// A recipe in the kitchen's grid: a picture of it, its title, and how long it takes or where it sits.
struct RecipeCard: View {
    /// What a card says under the title.
    enum Detail {
        /// How long the recipe takes, where its header says.
        case totalTime

        /// The names of the folders the recipe sits in, from the outermost down, as a search found it.
        case folder([String])
    }

    // The language the screen is written in, which is the one it reads a length of time in.
    private static let displayLocale = Locale(identifier: Bundle.module.preferredLocalizations.first ?? "en")

    private let card: KitchenRecipeCard
    private let detail: Detail

    init(_ card: KitchenRecipeCard, detail: Detail = .totalTime) {
        self.card = card
        self.detail = detail
    }

    var body: some View {
        KitchenCard(
            title: card.recipeEntry.title,
            picture: {
                RecipeCardPlaceholder(symbol: card.placeholderSymbol, color: card.placeholderColor)
                    .overlay(alignment: .topTrailing) {
                        RecipeAvailabilityBadge(card.recipeEntry.availability)
                            .padding(SousSpacing.small)
                    }
            },
            detail: { detailText }
        )
    }

    @ViewBuilder
    private var detailText: some View {
        switch detail {
        case .totalTime:
            totalTime

        case .folder(let names):
            FolderPathText(names)
        }
    }

    @ViewBuilder
    private var totalTime: some View {
        switch card.recipeEntry.summary?.totalTime {
        case .duration(let duration):
            Text(verbatim: Self.text(of: duration, width: .abbreviated))
                .accessibilityLabel(Text(verbatim: Self.text(of: duration, width: .wide)))

        case .written(let text):
            Text(verbatim: text)

        case nil:
            EmptyView()
        }
    }

    /// A duration in hours and minutes, in the language the screen is shown in.
    private static func text(of duration: Duration, width: Duration.UnitsFormatStyle.UnitWidth) -> String {
        duration.formatted(.units(allowed: [.hours, .minutes], width: width).locale(displayLocale))
    }
}

private func previewCard(
    _ id: String,
    header: String,
    availability: RecipeAvailability = .downloaded
) -> KitchenRecipeCard {
    let parser = SousParser()

    return KitchenFeaturePresenter.card(
        for: RecipeEntry(
            id: id,
            name: id.replacing("-", with: " "),
            availability: availability,
            summary: RecipeSummary(recipe: parser.parseRecipe(header).value, parser: parser)
        )
    )
}

private func previewCards() -> [KitchenRecipeCard] {
    [
        previewCard(
            "boeuf-bourguignon",
            header: "---\ntitle: Boeuf Bourguignon\nprep-time: 30 min\ncook-time: 3 h\n---"
        ),
        previewCard(
            "every-example",
            header: """
            ---
            title: Boeuf Bourguignon, Bouillabaisse, Brioche, Crepes, Croque Monsieur, Gratin Dauphinois, \
            Madeleines, Moules Marinieres, Quiche Lorraine, and Vinaigrette
            ---
            """
        ),
        previewCard(
            "crepes",
            header: "---\ntitle: Crepes\nprep-time: 10 min\ncook-time: 25 min\n---",
            availability: .notDownloaded
        ),
        previewCard(
            "steps-only",
            header: "Whisk @{1 tsp} dijon mustard@.",
            availability: .downloading
        )
    ]
}

#Preview("Recipe cards") {
    ScrollView {
        RecipeCardGrid(minimumColumnWidth: 160.0, spacing: SousSpacing.medium) {
            ForEach(previewCards()) { card in
                RecipeCard(card)
            }
        }
        .sousPagePadding()
    }
    .sousPage()
}

#Preview("Recipe cards, found by a search") {
    ScrollView {
        RecipeCardGrid(minimumColumnWidth: 160.0, spacing: SousSpacing.medium) {
            RecipeCard(previewCards()[0], detail: .folder(["Recipes", "French", "Classic"]))

            RecipeCard(previewCards()[2], detail: .folder(["Baking"]))
        }
        .sousPagePadding()
    }
    .sousPage()
}

#Preview("Recipe cards, one column") {
    ScrollView {
        RecipeCardGrid(minimumColumnWidth: 400.0, spacing: SousSpacing.medium) {
            ForEach(previewCards()) { card in
                RecipeCard(card)
            }
        }
        .sousPagePadding()
    }
    .sousPage()
    .dynamicTypeSize(.accessibility3)
}
