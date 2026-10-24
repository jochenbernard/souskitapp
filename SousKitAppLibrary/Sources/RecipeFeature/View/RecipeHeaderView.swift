import DesignSystem
import RecipeLibrary
import SwiftUI
import UIKit

/// The top of the recipe screen: the recipe's picture, or its placeholder, with where the recipe sits and its title
/// over the bottom of it.
struct RecipeHeaderView: View {
    @Environment(\.displayScale) private var displayScale

    /// The picture as it is listed now, at the size the header shows it.
    private struct Request: Equatable {
        let picture: RecipePicture?
        let pixelSize: CGSize
    }

    /// Where the header sits on the screen.
    enum Placement {
        /// Across the top of the screen, reaching under the bars.
        case hero

        /// At the top of the header card, where the overview stands beside the steps.
        case card
    }

    private static let heroHeight = 470.0

    // A little taller than a kitchen card's picture, so the title has room over it.
    private static let cardAspectRatio = 4.0 / 3.0

    // Light enough that the dish stays recognisable behind the title.
    private static let blurRadius = 8.0

    // Dark enough that white text holds on a pale picture.
    private static let washOpacity = 0.4

    @State private var size = CGSize.zero
    @State private var captionHeight = 0.0

    // A placeholder's symbol, larger than any text style, growing with Dynamic Type.
    @ScaledMetric(relativeTo: .largeTitle) private var heroSymbolSize = 68.0
    @ScaledMetric(relativeTo: .title) private var cardSymbolSize = 54.0

    private let presenter: RecipeFeaturePresenterProtocol
    private let viewModel: RecipeFeatureViewModel
    private let placeholder: RecipePlaceholder
    private let title: String
    private let placement: Placement
    private let barBottom: Double
    @Binding private var isTitleUnderBar: Bool

    /// - Parameters:
    ///   - placeholder: What stands in for the picture where the recipe has none.
    ///   - title: The recipe's title, as the screen names it.
    ///   - barBottom: Where the navigation bar ends, in global coordinates.
    ///   - isTitleUnderBar: Whether the title has scrolled under the navigation bar, set as it does.
    init(
        presenter: RecipeFeaturePresenterProtocol,
        viewModel: RecipeFeatureViewModel,
        placeholder: RecipePlaceholder,
        title: String,
        placement: Placement,
        barBottom: Double,
        isTitleUnderBar: Binding<Bool>
    ) {
        self.presenter = presenter
        self.viewModel = viewModel
        self.placeholder = placeholder
        self.title = title
        self.placement = placement
        self.barBottom = barBottom
        self._isTitleUnderBar = isTitleUnderBar
    }

    var body: some View {
        shape
            // A title too long for the picture makes it taller, rather than reaching past its top.
            .frame(minHeight: captionHeight + roomAboveCaption)
            .background {
                picture
            }
            .overlay(alignment: .bottomLeading) {
                caption
            }
            .onGeometryChange(for: CGSize.self, of: \.size) { newSize in
                size = newSize
            }
            .task(id: request) {
                await presenter.headerDidAppear(filling: request.pixelSize)
            }
    }

    /// The header's size where its title fits.
    @ViewBuilder
    private var shape: some View {
        switch placement {
        case .hero:
            Color.clear
                .frame(height: Self.heroHeight)

        case .card:
            Color.clear
                .aspectRatio(Self.cardAspectRatio, contentMode: .fit)
        }
    }

    /// What stays clear above the caption: the bar, over the hero, and a placeholder's symbol.
    private var roomAboveCaption: Double {
        let pictureRoom = isPlaceholder ? symbolHeight + SousSpacing.large * 2.0 : SousSpacing.large

        return pictureTop + pictureRoom
    }

    /// Where the picture shows from: below the bar, over the hero.
    private var pictureTop: Double {
        switch placement {
        case .hero:
            barBottom

        case .card:
            0.0
        }
    }

    private var isPlaceholder: Bool {
        switch viewModel.headerPicture {
        case .placeholder:
            true

        case .reading, .read:
            false
        }
    }

    private var symbolSize: Double {
        placement == .hero ? heroSymbolSize : cardSymbolSize
    }

    // Taller than its point size, by as much as the symbol's own shape takes.
    private var symbolHeight: Double {
        let configuration = UIImage.SymbolConfiguration(pointSize: symbolSize)

        guard let image = UIImage(systemName: placeholder.symbol, withConfiguration: configuration) else {
            return symbolSize
        }

        return image.size.height
    }

    @ViewBuilder
    private var picture: some View {
        switch viewModel.headerPicture {
        case .read(let image):
            photo(image)

        case .placeholder:
            SousPlaceholder(
                symbol: placeholder.symbol,
                color: placeholder.color,
                symbolFont: .system(size: symbolSize),
                symbolInsets: EdgeInsets(
                    top: pictureTop,
                    leading: 0.0,
                    bottom: captionHeight,
                    trailing: 0.0
                )
            )

        case .reading:
            Color.clear
        }
    }

    private func photo(_ image: CGImage) -> some View {
        Color.clear
            .overlay {
                Image(decorative: image, scale: displayScale)
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
            .bottomBlur(
                radius: Self.blurRadius,
                height: blurHeight,
                fullHeight: captionBand / 2.0
            )
            .overlay {
                wash
            }
    }

    /// The band the caption stands in, with room above it.
    private var captionBand: Double {
        captionHeight + SousSpacing.xLarge
    }

    /// How far up from the bottom the blur and the wash reach, fading out above the caption's band.
    private var blurHeight: Double {
        captionBand + (placement == .hero ? 78.0 : 54.0)
    }

    private var wash: some View {
        let start = max(0.0, 1.0 - blurHeight / max(size.height, 1.0))

        return LinearGradient(
            stops: [
                .init(color: .black.opacity(0.0), location: start),
                .init(color: .black.opacity(Self.washOpacity), location: start + (1.0 - start) * 0.6)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var caption: some View {
        VStack(alignment: .leading, spacing: SousSpacing.xSmall) {
            SousFolderPath(viewModel.folderPath)
                .font(.subheadline)
                .foregroundStyle(isOnPhoto ? AnyShapeStyle(.white.opacity(0.85)) : AnyShapeStyle(.secondary))

            titleText
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding([.horizontal, .bottom], SousSpacing.large)
        .fixedSize(horizontal: false, vertical: true)
        .onGeometryChange(for: CGFloat.self, of: \.size.height) { height in
            captionHeight = height
        }
        .accessibilityElement(children: .contain)
    }

    private var isOnPhoto: Bool {
        switch viewModel.headerPicture {
        case .read:
            true

        case .reading, .placeholder:
            false
        }
    }

    private var titleText: some View {
        let shownBarBottom = barBottom

        return Text(verbatim: title)
            .font(placement == .hero ? .largeTitle.bold() : .title.bold())
            .foregroundStyle(isOnPhoto ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .accessibilityAddTraits(.isHeader)
            // Read before the folders, which only say where the recipe sits.
            .accessibilitySortPriority(1.0)
            .onGeometryChange(
                for: Bool.self,
                of: { $0.frame(in: .global).maxY < shownBarBottom },
                action: { isTitleUnderBar = $0 }
            )
    }

    private var request: Request {
        Request(
            picture: viewModel.picture,
            pixelSize: CGSize(
                width: (size.width * displayScale).rounded(.up),
                height: (size.height * displayScale).rounded(.up)
            )
        )
    }
}

@MainActor
private func previewViewModel(_ headerPicture: HeaderPicture) -> RecipeFeatureViewModel {
    let viewModel = RecipeFeatureViewModel(
        recipeEntry: RecipeEntry(
            id: "madeleines",
            name: "madeleines",
            availability: .downloaded
        ),
        folderPath: ["Recipes", "French", "Baking"]
    )
    viewModel.headerPicture = headerPicture

    return viewModel
}

#Preview("Recipe header") {
    ScrollView {
        RecipeHeaderView(
            presenter: RecipeFeaturePresenterStub(),
            viewModel: previewViewModel(.placeholder),
            placeholder: RecipePlaceholder(symbol: "birthday.cake", color: .orange),
            title: "Madeleines",
            placement: .hero,
            barBottom: 0.0,
            isTitleUnderBar: .constant(false)
        )
    }
    .ignoresSafeArea(.container, edges: .top)
    .sousPage()
}

#Preview("Recipe header, on a card") {
    RecipeHeaderView(
        presenter: RecipeFeaturePresenterStub(),
        viewModel: previewViewModel(.placeholder),
        placeholder: RecipePlaceholder(symbol: "birthday.cake", color: .orange),
        title: "Madeleines",
        placement: .card,
        barBottom: 0.0,
        isTitleUnderBar: .constant(false)
    )
    .frame(width: 360.0)
    .sousRowSurface()
    .sousPagePadding()
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .topLeading
    )
    .sousPage()
}
