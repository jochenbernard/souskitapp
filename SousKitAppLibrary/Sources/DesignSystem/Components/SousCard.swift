import SwiftUI

/// A card: a picture, a title under it, and a line about what the card stands for.
///
/// It fills the height it is offered, so the cards sharing a row of a grid end level.
public struct SousCard<Picture: View, Detail: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private static var pictureAspectRatio: Double {
        16.0 / 10.0
    }

    private static var titleLineLimit: Int {
        2
    }

    @LineContainerRadius private var radius

    private let title: String
    private let picture: Picture
    private let detail: Detail

    /// Creates a card.
    ///
    /// - Parameters:
    ///   - title: What the card names.
    ///   - picture: The picture, filling the card's width and cropped to it.
    ///   - detail: The line under the title.
    public init(
        title: String,
        @ViewBuilder picture: () -> Picture,
        @ViewBuilder detail: () -> Detail
    ) {
        self.title = title
        self.picture = picture()
        self.detail = detail()
    }

    public var body: some View {
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
            .sousCardPicture()
    }

    private var caption: some View {
        VStack(alignment: .leading, spacing: SousSpacing.xSmall) {
            Text(verbatim: title)
                // At accessibility sizes a grid has one column, which leaves room for the whole title.
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : Self.titleLineLimit)

            detail
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SousSpacing.medium)
        // Sized before the picture, so a title taller than the picture is not cut a line short.
        .layoutPriority(1.0)
    }
}

#Preview("Cards") {
    ScrollView {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 160.0), spacing: SousSpacing.medium)],
            spacing: SousSpacing.medium
        ) {
            SousCard(
                title: "Crepes",
                picture: { SousPlaceholder(symbol: "fork.knife", color: .orange) },
                detail: { Text(verbatim: "35 min") }
            )

            SousCard(
                title: "Boeuf Bourguignon, Bouillabaisse, Brioche, Crepes, Croque Monsieur, and Gratin Dauphinois",
                picture: { SousPlaceholder(symbol: "fork.knife", color: .blue) },
                detail: { EmptyView() }
            )
        }
        .sousPagePadding()
    }
    .sousPage()
}
