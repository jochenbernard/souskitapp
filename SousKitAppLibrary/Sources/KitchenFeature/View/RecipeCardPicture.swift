import DesignSystem
import RecipeLibrary
import SwiftUI

/// What a card shows of a recipe: the picture its header names, filling the card's picture and cropped to it, a
/// loading placeholder while the picture is read or not known yet, or the recipe's placeholder where it names none or
/// it cannot be read.
struct RecipeCardPicture: View {
    @Environment(\.displayScale) private var displayScale

    /// The picture as it is listed now, at the size the card shows it.
    private struct Request: Equatable {
        let picture: RecipePicture?
        let pixelSize: CGSize
    }

    private static let arrivalDuration = 0.35
    private static let arrival = Animation.spring(duration: arrivalDuration, bounce: 0.0)
    // Once the picture fading in over it is opaque.
    private static let placeholderRemoval = AnyTransition.opacity.animation(arrival.delay(arrivalDuration))

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
            // The request it started for, not the card's by the time it runs, so the size landing reads once.
            .task(id: request) { [request] in
                await show(request)
            }
    }

    private var content: some View {
        ZStack {
            if shownImage == nil {
                // In a container of its own, so a placeholder changing kind takes none of its transition.
                ZStack {
                    placeholder
                }
                .transition(.asymmetric(insertion: .identity, removal: Self.placeholderRemoval))
            }

            if let image = shownImage {
                Image(decorative: image, scale: displayScale)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            }
        }
        .animation(Self.arrival, value: shownImage != nil)
    }

    private var shownImage: CGImage? {
        card.recipeEntry.picture.flatMap({ thumbnails[$0] })
    }

    @ViewBuilder
    private var placeholder: some View {
        if isPictureOnItsWay {
            Color.tertiaryFill
                .sousLoadingPlaceholder()
                .environment(\.isSousLoading, true)
        } else {
            SousPlaceholder(symbol: symbols[card.id], color: card.placeholderColor)
        }
    }

    private var isPictureOnItsWay: Bool {
        guard let picture = card.recipeEntry.picture else {
            return !card.isPictureKnown
        }

        return !thumbnails.didFail(picture)
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
            .aspectRatio(16.0 / 10.0, contentMode: .fit)
        }
    }
    .sousPagePadding()
    .sousPage()
}

#Preview("Recipe card picture being read") {
    RecipeCardPicture(
        KitchenRecipeCard(
            recipeEntry: RecipeEntry(
                id: "Crepes",
                name: "Crepes",
                availability: .downloaded,
                picture: RecipePicture(
                    id: "crepes.jpg",
                    modificationDate: nil,
                    availability: .downloaded
                )
            )
        ),
        thumbnails: KitchenThumbnails(),
        symbols: KitchenSymbols(),
        presenter: KitchenFeaturePresenterStub()
    )
    .aspectRatio(16.0 / 10.0, contentMode: .fit)
    .frame(width: 180.0)
    .sousPagePadding()
    .sousPage()
}
