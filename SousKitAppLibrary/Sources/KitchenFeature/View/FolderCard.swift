import DesignSystem
import RecipeLibrary
import SwiftUI

/// A folder in the kitchen's grid, as large as a recipe's card: a stack of the recipes in it, its name, and how many
/// recipes it holds.
///
/// It fills the height the grid offers, so the cards sharing a row end level.
struct FolderCard: View {
    private static let pictureAspectRatio = 4.0 / 3.0
    private static let nameLineLimit = 3

    @LineContainerRadius private var radius

    private let folder: KitchenFolder

    init(_ folder: KitchenFolder) {
        self.folder = folder
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            picture

            caption
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .sousRowSurface()
        .clipShape(.rect(cornerRadius: radius))
        .contentShape(.rect(cornerRadius: radius))
        .accessibilityElement(children: .combine)
    }

    private var picture: some View {
        Color.clear
            .aspectRatio(Self.pictureAspectRatio, contentMode: .fit)
            .background {
                FolderCardStack(folder.stackedCards)
            }
            .clipped()
    }

    private var caption: some View {
        VStack(alignment: .leading, spacing: SousSpacing.xSmall) {
            Text(verbatim: folder.name)
                .lineLimit(Self.nameLineLimit)

            Text("\(folder.recipeCount) recipes", bundle: .module)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SousSpacing.medium)
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
            FolderCard(previewFolder(["Baking"], recipeCount: 5))

            FolderCard(previewFolder(["Comfort food"], recipeCount: 1))

            FolderCard(previewFolder(["Dinner"], recipeCount: 2))

            FolderCard(previewFolder(["French", "Classic"], recipeCount: 3))
        }
        .sousPagePadding()
    }
    .sousPage()
}

#Preview("Folder cards, largest text") {
    ScrollView {
        RecipeCardGrid(minimumColumnWidth: 400.0, spacing: SousSpacing.medium) {
            FolderCard(previewFolder(["Baking"], recipeCount: 5))

            FolderCard(previewFolder(["Comfort food"], recipeCount: 1))
        }
        .sousPagePadding()
    }
    .sousPage()
    .dynamicTypeSize(.accessibility5)
}
