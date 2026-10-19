import DesignSystem
import SwiftUI

/// A card in the kitchen's grid: a picture, a title under it, and a line about what the card stands for.
///
/// It fills the height the grid offers, so the cards sharing a row end level.
struct KitchenCard<Picture: View, Detail: View>: View {
    private static var pictureAspectRatio: Double {
        4.0 / 3.0
    }

    private static var titleLineLimit: Int {
        3
    }

    @LineContainerRadius private var radius

    private let title: String
    private let picture: Picture
    private let detail: Detail

    init(
        title: String,
        @ViewBuilder picture: () -> Picture,
        @ViewBuilder detail: () -> Detail
    ) {
        self.title = title
        self.picture = picture()
        self.detail = detail()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            framedPicture
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

    private var framedPicture: some View {
        Color.clear
            .aspectRatio(Self.pictureAspectRatio, contentMode: .fit)
            .background {
                picture
            }
    }

    private var caption: some View {
        VStack(alignment: .leading, spacing: SousSpacing.xSmall) {
            Text(verbatim: title)
                .lineLimit(Self.titleLineLimit)

            detail
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SousSpacing.medium)
    }
}

#Preview("Kitchen cards") {
    ScrollView {
        RecipeCardGrid(minimumColumnWidth: 160.0, spacing: SousSpacing.medium) {
            KitchenCard(
                title: "Crepes",
                picture: { RecipeCardPlaceholder(symbol: "fork.knife", color: .saffron) },
                detail: { Text(verbatim: "35 min") }
            )

            KitchenCard(
                title: "Boeuf Bourguignon, Bouillabaisse, Brioche, Crepes, Croque Monsieur, and Gratin Dauphinois",
                picture: { RecipeCardPlaceholder(symbol: "fork.knife", color: .ocean) },
                detail: { EmptyView() }
            )
        }
        .sousPagePadding()
    }
    .sousPage()
}
