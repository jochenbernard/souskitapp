import DesignSystem
import RecipeLibrary
import SousKit
import SwiftUI

/// A recipe in the kitchen's grid: a picture of it, its title, and how long it takes.
///
/// It fills the height the grid offers, so the cards sharing a row end level.
struct RecipeCard: View {
    private static let pictureAspectRatio = 16.0 / 10.0
    private static let titleLineLimit = 3

    // The language the screen is written in, which is the one it reads a length of time in.
    private static let displayLocale = Locale(identifier: Bundle.module.preferredLocalizations.first ?? "en")

    @LineContainerRadius private var radius

    private let card: KitchenRecipeCard

    init(_ card: KitchenRecipeCard) {
        self.card = card
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            picture
                // Read after the title, which names the card.
                .accessibilitySortPriority(-1.0)

            caption
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .sousRowSurface()
        .clipShape(.rect(cornerRadius: radius))
        .contentShape(.rect(cornerRadius: radius))
        .accessibilityElement(children: .combine)
    }

    private var picture: some View {
        Color.clear
            .aspectRatio(Self.pictureAspectRatio, contentMode: .fit)
            .background {
                RecipeCardPlaceholder(symbol: card.placeholderSymbol, color: card.placeholderColor)
            }
            .overlay(alignment: .topTrailing) {
                RecipeAvailabilityBadge(card.recipeEntry.availability)
                    .padding(SousSpacing.small)
            }
    }

    private var caption: some View {
        VStack(alignment: .leading, spacing: SousSpacing.xSmall) {
            Text(verbatim: card.recipeEntry.title)
                .lineLimit(Self.titleLineLimit)

            totalTime
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SousSpacing.medium)
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
