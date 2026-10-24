import DesignSystem
import RecipeLibrary
import SwiftUI

/// A recipe's card on a folder's page, which pushes the recipe, zooming out of the card, and whose long press shows
/// the recipe at a glance with a menu.
struct RecipeCardButton: View {
    @LineContainerRadius private var radius

    private let card: KitchenRecipeCard
    private let detail: RecipeCard.Detail
    private let folderPath: [String]
    private let presenter: KitchenFeaturePresenterProtocol
    private let viewModel: KitchenFeatureViewModel
    private let cardTransition: Namespace.ID
    private let previewSize: CGSize

    /// - Parameters:
    ///   - detail: What the card says under the title, which says where a recipe a search found sits.
    ///   - folderPath: The names of the folders leading down to the folder the page shows, or none for the top.
    ///   - cardTransition: Where the recipe's screen zooms out of the card.
    ///   - previewSize: The width the preview takes, and the most height.
    init(
        _ card: KitchenRecipeCard,
        detail: RecipeCard.Detail,
        folderPath: [String],
        presenter: KitchenFeaturePresenterProtocol,
        viewModel: KitchenFeatureViewModel,
        cardTransition: Namespace.ID,
        previewSize: CGSize
    ) {
        self.card = card
        self.detail = detail
        self.folderPath = folderPath
        self.presenter = presenter
        self.viewModel = viewModel
        self.cardTransition = cardTransition
        self.previewSize = previewSize
    }

    var body: some View {
        Button(action: open) {
            RecipeCard(
                card,
                thumbnails: viewModel.thumbnails,
                symbols: viewModel.symbols,
                presenter: presenter,
                detail: detail
            )
        }
        .buttonStyle(.plain)
        .contextMenu(
            menuItems: { menuItems },
            preview: {
                RecipeCardPreview(
                    card,
                    presenter: presenter,
                    viewModel: viewModel
                )
                .cardPreview(fitting: previewSize)
            }
        )
        .matchedTransitionSource(
            id: screen.cardID,
            in: cardTransition,
            configuration: { $0.clipShape(.rect(cornerRadius: radius)) }
        )
        // VoiceOver lists no context menu, so its choices beyond opening are the card's actions too.
        .accessibilityActions {
            actionItems
        }
    }

    private var screen: KitchenScreen {
        .recipe(card.recipeEntry)
    }

    /// The screen the page shows, which the recipe is pushed over.
    private var origin: KitchenScreen? {
        folderPath.isEmpty ? nil : .folder(folderPath)
    }

    @ViewBuilder
    private var menuItems: some View {
        Button(action: open) {
            Label(
                title: { Text("Open", bundle: .module) },
                icon: { Image(systemName: "arrow.up.forward.square") }
            )
        }

        actionItems
    }

    /// What the card does besides opening its recipe.
    @ViewBuilder
    private var actionItems: some View {
        Button(action: startCooking) {
            Label(
                title: { Text("Start cooking", bundle: .module) },
                icon: { Image(systemName: "frying.pan") }
            )
        }

        Button(action: scale) {
            Label(
                title: { Text("Scale", bundle: .module) },
                icon: { Image(systemName: "chevron.up.chevron.down") }
            )
        }

        folderItem
    }

    /// Show in folder, for a recipe a search found below the folder searched, which shows it outside its own folder.
    @ViewBuilder
    private var folderItem: some View {
        switch detail {
        case .totalTime:
            EmptyView()

        case .folder:
            if card.recipeEntry.folderPath != folderPath {
                Button(action: showFolder) {
                    Label(
                        title: { Text("Show in folder", bundle: .module) },
                        icon: { Image(systemName: "folder") }
                    )
                }
            }
        }
    }

    private func open() {
        presenter.didPush(screen, from: origin)
    }

    private func startCooking() {
        presenter.didChooseCooking(card.recipeEntry, from: origin)
    }

    private func scale() {
        presenter.didChooseScaling(card.recipeEntry, from: origin)
    }

    private func showFolder() {
        presenter.didChooseFolder(of: card.recipeEntry, from: origin)
    }
}

#Preview("Recipe card button") {
    @Previewable @Namespace var cardTransition

    RecipeCardButton(
        KitchenRecipeCard(
            recipeEntry: RecipeEntry(
                id: "Baking/brioche",
                name: "brioche",
                availability: .downloaded,
                folderPath: ["Baking"]
            )
        ),
        detail: .folder(["Recipes", "Baking"]),
        folderPath: [],
        presenter: KitchenFeaturePresenterStub(),
        viewModel: KitchenFeatureViewModel(recipeRepositoryName: "Recipes"),
        cardTransition: cardTransition,
        previewSize: CGSize(width: 370.0, height: 500.0)
    )
    .frame(width: 180.0)
    .sousPagePadding()
    .sousPage()
}
