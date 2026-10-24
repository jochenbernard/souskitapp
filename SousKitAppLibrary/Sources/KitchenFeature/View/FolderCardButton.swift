import DesignSystem
import RecipeLibrary
import SwiftUI

/// A folder's card on a folder's page, which pushes the folder, zooming out of the card, and whose long press shows
/// the folder at a glance with a menu.
struct FolderCardButton: View {
    @LineContainerRadius private var radius

    private let folder: KitchenFolder
    private let origin: KitchenScreen?
    private let presenter: KitchenFeaturePresenterProtocol
    private let viewModel: KitchenFeatureViewModel
    private let cardTransition: Namespace.ID
    private let previewSize: CGSize

    /// - Parameters:
    ///   - origin: The screen the card is on, or `nil` for the kitchen's own.
    ///   - cardTransition: Where the folder's screen zooms out of the card.
    ///   - previewSize: The width the preview takes, and the most height.
    init(
        _ folder: KitchenFolder,
        origin: KitchenScreen?,
        presenter: KitchenFeaturePresenterProtocol,
        viewModel: KitchenFeatureViewModel,
        cardTransition: Namespace.ID,
        previewSize: CGSize
    ) {
        self.folder = folder
        self.origin = origin
        self.presenter = presenter
        self.viewModel = viewModel
        self.cardTransition = cardTransition
        self.previewSize = previewSize
    }

    var body: some View {
        Button(action: open) {
            FolderCard(
                folder,
                thumbnails: viewModel.thumbnails,
                symbols: viewModel.symbols,
                presenter: presenter
            )
        }
        .buttonStyle(.plain)
        .contextMenu(
            menuItems: { menuItems },
            preview: {
                FolderPreview(
                    folder,
                    thumbnails: viewModel.thumbnails,
                    symbols: viewModel.symbols,
                    presenter: presenter
                )
                .cardPreview(fitting: previewSize)
            }
        )
        .matchedTransitionSource(
            id: screen.cardID,
            in: cardTransition,
            configuration: { $0.clipShape(.rect(cornerRadius: radius)) }
        )
        // VoiceOver lists no context menu, so its choice beyond opening is the card's action too.
        .accessibilityActions {
            searchItem
        }
    }

    private var screen: KitchenScreen {
        .folder(folder.path)
    }

    @ViewBuilder
    private var menuItems: some View {
        Button(action: open) {
            Label(
                title: { Text("Open", bundle: .module) },
                icon: { Image(systemName: "arrow.up.forward.square") }
            )
        }

        searchItem
    }

    private var searchItem: some View {
        Button(action: search) {
            Label(
                title: { Text("Search in \(folder.name)", bundle: .module) },
                icon: { Image(systemName: "magnifyingglass") }
            )
        }
    }

    private func open() {
        presenter.didPush(screen, from: origin)
    }

    private func search() {
        presenter.didChooseSearch(inFolderAt: folder.path, from: origin)
    }
}

#Preview("Folder card button") {
    @Previewable @Namespace var cardTransition

    FolderCardButton(
        KitchenFolderTree.folder(
            at: ["Baking"],
            holding: [
                RecipeEntry(
                    id: "Baking/brioche",
                    name: "Brioche",
                    availability: .downloaded,
                    folderPath: ["Baking"]
                )
            ]
        ),
        origin: nil,
        presenter: KitchenFeaturePresenterStub(),
        viewModel: KitchenFeatureViewModel(recipeRepositoryName: "Recipes"),
        cardTransition: cardTransition,
        previewSize: CGSize(width: 370.0, height: 500.0)
    )
    .frame(width: 180.0)
    .sousPagePadding()
    .sousPage()
}
