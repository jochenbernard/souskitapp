import DesignSystem
import RecipeLibrary
import SousKit
import SwiftUI

/// A recipe in the kitchen's grid: a picture of it, its title, and how long it takes.
///
/// It fills the height the grid offers, so the cards sharing a row end level.
struct RecipeCard: View {
    private static let pictureAspectRatio = 4.0 / 3.0
    private static let titleLineLimit = 3

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
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SousSpacing.medium)
    }

    @ViewBuilder
    private var totalTime: some View {
        switch card.totalTime {
        case .duration(let duration):
            Text(verbatim: Self.text(of: duration, width: .abbreviated))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityLabel(Text(verbatim: Self.text(of: duration, width: .wide)))

        case .written(let text):
            Text(verbatim: text)
                .font(.subheadline)
                .foregroundStyle(.secondary)

        case nil:
            EmptyView()
        }
    }

    /// A duration in hours and minutes, in the language the screen is shown in.
    private static func text(of duration: Duration, width: Duration.UnitsFormatStyle.UnitWidth) -> String {
        let locale = Locale(identifier: Bundle.module.preferredLocalizations.first ?? "en")

        return duration.formatted(.units(allowed: [.hours, .minutes], width: width).locale(locale))
    }
}

private func previewCard(
    _ id: String,
    header: String,
    availability: RecipeAvailability = .downloaded
) -> KitchenRecipeCard {
    let parser = SousParser()
    let summary = RecipeSummary(recipe: parser.parseRecipe(header).value)

    return KitchenRecipeCard(
        recipeEntry: RecipeEntry(
            id: id,
            name: id.replacing("-", with: " "),
            availability: availability,
            summary: summary
        ),
        totalTime: TotalTime(metadata: summary.metadata, parser: parser),
        placeholderSymbol: "fork.knife",
        placeholderColor: PlaceholderColorPick.color(forTitle: summary.metadata.title ?? id)
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
