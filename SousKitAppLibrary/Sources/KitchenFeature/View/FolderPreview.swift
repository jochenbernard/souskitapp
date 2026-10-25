import DesignSystem
import RecipeLibrary
import SwiftUI

/// A glance at a folder before it is opened: its name, how many recipes it holds, and its first cards as its page
/// shows them.
struct FolderPreview: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // A preview cannot scroll, and past this size its heading and one card outgrow it.
    private static let largestTypeSize = DynamicTypeSize.accessibility1
    // Past this size two rows of cards outgrow the preview.
    private static let largestTwoRowTypeSize = DynamicTypeSize.large

    // Two columns of cards, or one at accessibility sizes, where a card is as wide as the preview.
    private static let wideColumnCount = 2
    private static let maximumRowCount = 2

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
        VStack(alignment: .leading, spacing: SousSpacing.medium) {
            heading

            cardGrid

            remainder
        }
        .padding(SousSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dynamicTypeSize(...Self.largestTypeSize)
        .sousPage()
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: SousSpacing.xSmall) {
            Text(verbatim: folder.name)
                .font(.title.bold())
                .accessibilityAddTraits(.isHeader)

            Text("\(folder.recipeCount) recipes", bundle: .module)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var cardGrid: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(spacing: SousSpacing.medium), count: columnCount),
            spacing: SousSpacing.medium
        ) {
            ForEach(shownFolders) { innerFolder in
                FolderCard(
                    innerFolder,
                    thumbnails: thumbnails,
                    symbols: symbols,
                    presenter: presenter
                )
            }

            ForEach(shownCards) { card in
                RecipeCard(
                    card,
                    thumbnails: thumbnails,
                    symbols: symbols,
                    presenter: presenter
                )
            }
        }
    }

    @ViewBuilder
    private var remainder: some View {
        let count = folder.folders.count + folder.cards.count - shownFolders.count - shownCards.count

        if count > 0 {
            Text("and \(count) more", bundle: .module)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var columnCount: Int {
        dynamicTypeSize.isAccessibilitySize ? 1 : Self.wideColumnCount
    }

    private var rowCount: Int {
        dynamicTypeSize > Self.largestTwoRowTypeSize ? 1 : Self.maximumRowCount
    }

    private var shownCount: Int {
        columnCount * rowCount
    }

    /// The folders inside this one that the preview shows, which come before its recipes as on its page.
    private var shownFolders: ArraySlice<KitchenFolder> {
        folder.folders.prefix(shownCount)
    }

    private var shownCards: ArraySlice<KitchenRecipeCard> {
        folder.cards.prefix(shownCount - shownFolders.count)
    }
}

private func previewFolder(_ path: [String], recipeCount: Int) -> KitchenFolder {
    let titles = ["Brioche", "Crepes", "Madeleines", "Quiche Lorraine", "Vinaigrette", "Bouillabaisse"]
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

#Preview("Folder preview") {
    FolderPreview(
        previewFolder(["Baking"], recipeCount: 6),
        thumbnails: KitchenThumbnails(),
        symbols: KitchenSymbols(),
        presenter: KitchenFeaturePresenterStub()
    )
    .frame(width: 370.0)
    .fixedSize(horizontal: false, vertical: true)
}

#Preview("Folder preview, one recipe") {
    FolderPreview(
        previewFolder(["Baking"], recipeCount: 1),
        thumbnails: KitchenThumbnails(),
        symbols: KitchenSymbols(),
        presenter: KitchenFeaturePresenterStub()
    )
    .frame(width: 370.0)
    .fixedSize(horizontal: false, vertical: true)
}

#Preview("Folder preview, largest text") {
    FolderPreview(
        previewFolder(["Baking"], recipeCount: 6),
        thumbnails: KitchenThumbnails(),
        symbols: KitchenSymbols(),
        presenter: KitchenFeaturePresenterStub()
    )
    .frame(width: 370.0)
    .fixedSize(horizontal: false, vertical: true)
    .dynamicTypeSize(.accessibility5)
}
