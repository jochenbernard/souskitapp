import DesignSystem
import RecipeLibrary
import SwiftUI

/// What a folder's card shows for a picture: the pictures of the recipes in it, fanned out in a stack, the first on
/// top.
struct FolderCardStack: View {
    // Each card's share of the picture's width and height.
    private static let cardWidthShare = 0.5
    private static let cardHeightShare = 0.62
    private static let cardCornerRadius = 10.0
    private static let cardBorderWidth = 2.0
    // How far each card turns and moves from the middle of the fan.
    private static let fanAngle = 7.0
    private static let fanSpread = 14.0
    private static let fanRise = 4.0

    private let cards: [KitchenRecipeCard]
    private let thumbnails: KitchenThumbnails
    private let presenter: KitchenFeaturePresenterProtocol

    init(
        _ cards: [KitchenRecipeCard],
        thumbnails: KitchenThumbnails,
        presenter: KitchenFeaturePresenterProtocol
    ) {
        self.cards = cards
        self.thumbnails = thumbnails
        self.presenter = presenter
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Array(cards.enumerated().reversed()), id: \.element.id) { index, card in
                    picture(of: card, readSize: geometry.size)
                        .frame(
                            width: geometry.size.width * Self.cardWidthShare,
                            height: geometry.size.height * Self.cardHeightShare
                        )
                        .clipShape(.rect(cornerRadius: Self.cardCornerRadius))
                        .overlay {
                            RoundedRectangle(cornerRadius: Self.cardCornerRadius)
                                .stroke(.secondaryGroupedBackground, lineWidth: Self.cardBorderWidth)
                        }
                        .rotationEffect(.degrees(-fanPosition(of: index) * Self.fanAngle))
                        .offset(
                            x: -fanPosition(of: index) * Self.fanSpread,
                            y: -Double(index) * Self.fanRise
                        )
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .background(.tertiaryFill)
        .accessibilityHidden(true)
    }

    // What the recipe's own card shows above its title, read at that card's size so both share one thumbnail.
    private func picture(of card: KitchenRecipeCard, readSize: CGSize) -> some View {
        RecipeCardPicture(
            card,
            thumbnails: thumbnails,
            presenter: presenter,
            readSize: readSize
        )
            .background(.secondaryGroupedBackground)
    }

    /// Where a card sits in the fan, from the left end at minus half the count to the right end at plus half.
    private func fanPosition(of index: Int) -> Double {
        Double(index) - Double(cards.count - 1) / 2.0
    }
}

private func previewCards(_ count: Int) -> [KitchenRecipeCard] {
    ["Brioche", "Crepes", "Madeleines", "Quiche Lorraine"].prefix(count).map { title in
        KitchenFeaturePresenter.card(
            for: RecipeEntry(
                id: title,
                name: title,
                availability: .downloaded
            )
        )
    }
}

#Preview("Folder card stacks") {
    VStack(spacing: SousSpacing.medium) {
        ForEach(1...4, id: \.self) { count in
            FolderCardStack(
                previewCards(count),
                thumbnails: KitchenThumbnails(),
                presenter: KitchenFeaturePresenterStub()
            )
                .aspectRatio(4.0 / 3.0, contentMode: .fit)
        }
    }
    .frame(width: 180.0)
    .sousPagePadding()
    .sousPage()
}
