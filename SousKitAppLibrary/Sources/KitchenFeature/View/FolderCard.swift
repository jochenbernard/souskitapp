import DesignSystem
import RecipeLibrary
import SwiftUI

/// A folder in the kitchen's grid, as large as a recipe's card: a stack of the recipes in it, its name, and how many
/// recipes it holds.
struct FolderCard: View {
    private let folder: KitchenFolder
    private let presenter: KitchenFeaturePresenterProtocol

    init(_ folder: KitchenFolder, presenter: KitchenFeaturePresenterProtocol) {
        self.folder = folder
        self.presenter = presenter
    }

    var body: some View {
        KitchenCard(
            title: folder.name,
            // Clipped, as the fan reaches past the picture's edges.
            picture: { FolderCardStack(folder.stackedCards, presenter: presenter).clipped() },
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
            FolderCard(previewFolder(["Baking"], recipeCount: 5), presenter: KitchenFeaturePresenterStub())

            FolderCard(previewFolder(["Comfort food"], recipeCount: 1), presenter: KitchenFeaturePresenterStub())

            FolderCard(previewFolder(["Dinner"], recipeCount: 2), presenter: KitchenFeaturePresenterStub())

            FolderCard(previewFolder(["French", "Classic"], recipeCount: 3), presenter: KitchenFeaturePresenterStub())
        }
        .sousPagePadding()
    }
    .sousPage()
}

#Preview("Folder cards, largest text") {
    ScrollView {
        RecipeCardGrid(minimumColumnWidth: 400.0, spacing: SousSpacing.medium) {
            FolderCard(previewFolder(["Baking"], recipeCount: 5), presenter: KitchenFeaturePresenterStub())

            FolderCard(previewFolder(["Comfort food"], recipeCount: 1), presenter: KitchenFeaturePresenterStub())
        }
        .sousPagePadding()
    }
    .sousPage()
    .dynamicTypeSize(.accessibility5)
}
