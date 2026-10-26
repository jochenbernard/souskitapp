import DesignSystem
import RecipeLibrary
import SwiftUI

/// A folder in the kitchen's grid, as large as a recipe's card: a stack of the recipes in it, its name, and how many
/// recipes it holds.
struct FolderCard: View {
    private let folder: KitchenFolder
    private let thumbnails: KitchenThumbnails
    private let symbols: KitchenSymbols
    private let presenter: KitchenFeaturePresenterProtocol

    init(
        _ folder: KitchenFolder,
        thumbnails: KitchenThumbnails,
        symbols: KitchenSymbols,
        presenter: KitchenFeaturePresenterProtocol
    ) {
        self.folder = folder
        self.thumbnails = thumbnails
        self.symbols = symbols
        self.presenter = presenter
    }

    var body: some View {
        SousCard(
            title: folder.name,
            // Clipped, as the fan reaches past the picture's edges.
            picture: {
                FolderCardStack(
                    folder.stackedCards,
                    thumbnails: thumbnails,
                    symbols: symbols,
                    presenter: presenter
                )
                .clipped()
            },
            detail: { Text("\(folder.recipeCount) recipes", bundle: .module) }
        )
    }
}

private func previewFolder(_ path: [String], recipeCount: Int) -> KitchenFolder {
    let titles = ["Brioche", "Crepes", "Madeleines", "Quiche Lorraine", "Vinaigrette"]
    let entries = titles.prefix(recipeCount).map { title in
        RecipeEntry(
            id: (path + [title]).joined(separator: "/"),
            name: title,
            availability: .downloaded,
            folderPath: path
        )
    }

    return KitchenFolderTree.folder(at: path, holding: Array(entries))
}

#Preview("Folder cards") {
    ScrollView {
        RecipeCardGrid(minimumColumnWidth: 160.0, spacing: SousSpacing.medium) {
            FolderCard(
                previewFolder(["Baking"], recipeCount: 5),
                thumbnails: KitchenThumbnails(),
                symbols: KitchenSymbols(),
                presenter: KitchenFeaturePresenterStub()
            )

            FolderCard(
                previewFolder(["Comfort food"], recipeCount: 1),
                thumbnails: KitchenThumbnails(),
                symbols: KitchenSymbols(),
                presenter: KitchenFeaturePresenterStub()
            )

            FolderCard(
                previewFolder(["Dinner"], recipeCount: 2),
                thumbnails: KitchenThumbnails(),
                symbols: KitchenSymbols(),
                presenter: KitchenFeaturePresenterStub()
            )

            FolderCard(
                previewFolder(["French", "Classic"], recipeCount: 3),
                thumbnails: KitchenThumbnails(),
                symbols: KitchenSymbols(),
                presenter: KitchenFeaturePresenterStub()
            )
        }
        .sousPagePadding()
    }
    .sousPage()
}

#Preview("Folder cards, largest text") {
    ScrollView {
        RecipeCardGrid(minimumColumnWidth: 400.0, spacing: SousSpacing.medium) {
            FolderCard(
                previewFolder(["Baking"], recipeCount: 5),
                thumbnails: KitchenThumbnails(),
                symbols: KitchenSymbols(),
                presenter: KitchenFeaturePresenterStub()
            )

            FolderCard(
                previewFolder(["Comfort food"], recipeCount: 1),
                thumbnails: KitchenThumbnails(),
                symbols: KitchenSymbols(),
                presenter: KitchenFeaturePresenterStub()
            )
        }
        .sousPagePadding()
    }
    .sousPage()
    .dynamicTypeSize(.accessibility5)
}
