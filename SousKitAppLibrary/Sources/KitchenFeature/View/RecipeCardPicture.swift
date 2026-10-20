import DesignSystem
import RecipeLibrary
import SwiftUI

/// What a card shows of a recipe: the picture its header names, filling the card's picture and cropped to it, or the
/// recipe's placeholder until the picture is read and wherever it cannot be.
struct RecipeCardPicture: View {
    @Environment(\.displayScale) private var displayScale

    /// The picture as it is listed now, at the size the card shows it.
    private struct Request: Equatable {
        let picture: RecipePicture?
        let pixelSize: CGSize
    }

    @State private var size = CGSize.zero

    private let card: KitchenRecipeCard
    private let thumbnails: KitchenThumbnails
    private let symbols: KitchenSymbols
    private let presenter: KitchenFeaturePresenterProtocol
    private let readSize: CGSize?

    /// - Parameter readSize: The box the picture is read to fill, where it is shown smaller than on the recipe's own
    ///   card, or `nil` for the box it is shown in.
    init(
        _ card: KitchenRecipeCard,
        thumbnails: KitchenThumbnails,
        symbols: KitchenSymbols,
        presenter: KitchenFeaturePresenterProtocol,
        readSize: CGSize? = nil
    ) {
        self.card = card
        self.thumbnails = thumbnails
        self.symbols = symbols
        self.presenter = presenter
        self.readSize = readSize
    }

    var body: some View {
        Color.clear
            .overlay {
                content
            }
            .clipped()
            .onGeometryChange(for: CGSize.self, of: \.size) { newSize in
                size = newSize
            }
            .task(id: request) {
                await show(request)
            }
    }

    @ViewBuilder
    private var content: some View {
        if let image = shownImage {
            Image(decorative: image, scale: displayScale)
                .resizable()
                .scaledToFill()
        } else {
            RecipeCardPlaceholder(symbol: symbols[card.id], color: card.placeholderColor)
        }
    }

    private var shownImage: CGImage? {
        card.recipeEntry.picture.flatMap({ thumbnails[$0] })
    }

    private var request: Request {
        let boxSize = readSize ?? size

        return Request(
            picture: card.recipeEntry.picture,
            pixelSize: CGSize(
                width: (boxSize.width * displayScale).rounded(.up),
                height: (boxSize.height * displayScale).rounded(.up)
            )
        )
    }

    private func show(_ request: Request) async {
        guard
            let picture = request.picture,
            request.pixelSize.width > 0.0,
            request.pixelSize.height > 0.0
        else {
            return
        }

        await presenter.pictureDidAppear(picture, filling: request.pixelSize)
    }
}

#Preview("Recipe card pictures") {
    HStack(spacing: SousSpacing.medium) {
        ForEach(["Brioche", "Crepes"], id: \.self) { title in
            RecipeCardPicture(
                KitchenRecipeCard(
                    recipeEntry: RecipeEntry(
                        id: title,
                        name: title,
                        availability: .downloaded
                    )
                ),
                thumbnails: KitchenThumbnails(),
                symbols: KitchenSymbols(),
                presenter: KitchenFeaturePresenterStub()
            )
            .aspectRatio(4.0 / 3.0, contentMode: .fit)
        }
    }
    .sousPagePadding()
    .sousPage()
}
