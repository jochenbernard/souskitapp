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
    // What the card read last, which it keeps showing while a replaced picture is read.
    @State private var thumbnail: CGImage?

    private let card: KitchenRecipeCard
    private let presenter: KitchenFeaturePresenterProtocol

    init(_ card: KitchenRecipeCard, presenter: KitchenFeaturePresenterProtocol) {
        self.card = card
        self.presenter = presenter
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
                await read(request)
            }
    }

    @ViewBuilder
    private var content: some View {
        if let image = shownImage {
            Image(decorative: image, scale: displayScale)
                .resizable()
                .scaledToFill()
        } else {
            RecipeCardPlaceholder(symbol: card.placeholderSymbol, color: card.placeholderColor)
        }
    }

    private var shownImage: CGImage? {
        guard let picture = card.recipeEntry.picture else {
            return nil
        }

        return thumbnail ?? presenter.lastThumbnail(of: picture)
    }

    private var request: Request {
        Request(
            picture: card.recipeEntry.picture,
            pixelSize: CGSize(
                width: (size.width * displayScale).rounded(.up),
                height: (size.height * displayScale).rounded(.up)
            )
        )
    }

    private func read(_ request: Request) async {
        guard let picture = request.picture else {
            thumbnail = nil
            return
        }

        guard request.pixelSize.width > 0.0, request.pixelSize.height > 0.0 else {
            return
        }

        let readThumbnail = await presenter.thumbnail(of: picture, filling: request.pixelSize)

        // A card scrolled away or resized meanwhile reads again, or never shows what was read.
        guard !Task.isCancelled else {
            return
        }

        thumbnail = readThumbnail
    }
}

#Preview("Recipe card pictures") {
    HStack(spacing: SousSpacing.medium) {
        ForEach(["Brioche", "Crepes"], id: \.self) { title in
            RecipeCardPicture(
                KitchenFeaturePresenter.card(
                    for: RecipeEntry(
                        id: title,
                        name: title,
                        availability: .downloaded
                    )
                ),
                presenter: KitchenFeaturePresenterStub()
            )
            .aspectRatio(4.0 / 3.0, contentMode: .fit)
        }
    }
    .sousPagePadding()
    .sousPage()
}
