import DesignSystem
import RecipeLibrary
import SwiftUI

/// A folder's card on a folder's page, which pushes the folder, and whose long press shows the folder at a glance with
/// a menu.
struct FolderCardButton: View {
    private let folder: KitchenFolder
    private let origin: KitchenScreen?
    private let presenter: KitchenFeaturePresenterProtocol
    private let viewModel: KitchenFeatureViewModel
    private let previewSize: CGSize

    /// - Parameters:
    ///   - origin: The screen the card is on, or `nil` for the kitchen's own.
    ///   - previewSize: The width the preview takes, and the most height.
    init(
        _ folder: KitchenFolder,
        origin: KitchenScreen?,
        presenter: KitchenFeaturePresenterProtocol,
        viewModel: KitchenFeatureViewModel,
        previewSize: CGSize
    ) {
        self.folder = folder
        self.origin = origin
        self.presenter = presenter
        self.viewModel = viewModel
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
        .cardMenu(
            items: [
                CardMenuItem(
                    title: String(localized: "Search in \(folder.name)", bundle: .module),
                    systemImage: "magnifyingglass",
                    action: search
                )
            ],
            open: open,
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
    }

    private var screen: KitchenScreen {
        .folder(folder.path)
    }

    private func open() {
        presenter.didPush(screen, from: origin)
    }

    private func search() {
        presenter.didChooseSearch(inFolderAt: folder.path, from: origin)
    }
}

#Preview("Folder card button") {
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
        previewSize: CGSize(width: 370.0, height: 500.0)
    )
    .frame(width: 180.0)
    .sousPagePadding()
    .sousPage()
}
