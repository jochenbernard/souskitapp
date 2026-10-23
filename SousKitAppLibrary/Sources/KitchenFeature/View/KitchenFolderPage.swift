import DesignSystem
import RecipeLibrary
import SwiftUI

/// What a folder of the repository holds, as the kitchen's top screen or a screen pushed for the folder shows it:
/// the folders inside it and its recipes, as cards.
struct KitchenFolderPage: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @ScaledMetric(relativeTo: .body) private var scaledCardWidth = Self.minimumCardWidth

    // Two columns on any iPhone; at accessibility sizes the width grows with the text, which leaves the iPhone one.
    private static let minimumCardWidth = 160.0

    // The names of the folders leading down to the folder, or none for the top of the repository.
    private let path: [String]
    private let presenter: KitchenFeaturePresenterProtocol
    private let viewModel: KitchenFeatureViewModel

    init(
        path: [String],
        presenter: KitchenFeaturePresenterProtocol,
        viewModel: KitchenFeatureViewModel
    ) {
        self.path = path
        self.presenter = presenter
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            // A blank page, rather than a list the restored screens cover a moment later.
            if !viewModel.isRestoring {
                folderContents
                    .sousPagePadding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .sousPage()
    }

    @ViewBuilder
    private var folderContents: some View {
        switch viewModel.recipeList {
        case .reading:
            readingNote

        case .recipes(let topFolder):
            if let folder = topFolder.folder(at: path), !folder.isEmpty {
                folderView(folder)
            } else {
                emptyNote
            }

        case .failure(let message):
            failureNote(message)
        }
    }

    private var readingNote: some View {
        SousActivityNote {
            Text("Reading the folder.", bundle: .module)
        }
    }

    private func folderView(_ folder: KitchenFolder) -> some View {
        // The screen showing the folder, which its cards push over.
        let origin = folder.path.isEmpty ? nil : KitchenScreen.folder(folder.path)

        return RecipeCardGrid(
            minimumColumnWidth: dynamicTypeSize.isAccessibilitySize ? scaledCardWidth : Self.minimumCardWidth,
            spacing: SousSpacing.medium
        ) {
            ForEach(folder.folders) { innerFolder in
                Button(
                    action: { presenter.didPush(.folder(innerFolder.path), from: origin) },
                    label: { FolderCard(innerFolder) }
                )
                .buttonStyle(.plain)
            }

            ForEach(folder.cards) { card in
                Button(
                    action: { presenter.didPush(.recipe(card.recipeEntry), from: origin) },
                    label: { RecipeCard(card) }
                )
                .buttonStyle(.plain)
            }
        }
    }

    private var emptyNote: some View {
        VStack(alignment: .leading, spacing: SousSpacing.small) {
            Text("Nothing here yet", bundle: .module)

            Text("Put .sous files in this folder and they are listed here.", bundle: .module)
                .foregroundStyle(.secondary)
        }
    }

    private func failureNote(_ message: String) -> some View {
        SousFailureNote(Text("This folder could not be read", bundle: .module), message: message)
    }
}

@MainActor
private func previewViewModel() -> KitchenFeatureViewModel {
    let viewModel = KitchenFeatureViewModel(recipeRepositoryName: "Recipes")
    let entries = ["Baking/brioche", "Baking/madeleines", "Baking/Classic/crepes", "vinaigrette"].map { path in
        let components = path.split(separator: "/").map(String.init)

        return RecipeEntry(
            id: path,
            name: components.last ?? path,
            availability: .downloaded,
            folderPath: Array(components.dropLast())
        )
    }
    viewModel.recipeList = .recipes(KitchenFolderTree.folder(at: [], holding: entries))

    return viewModel
}

#Preview("Folder page, top") {
    NavigationStack {
        KitchenFolderPage(
            path: [],
            presenter: KitchenFeaturePresenterStub(),
            viewModel: previewViewModel()
        )
        .navigationTitle("Recipes")
    }
}

#Preview("Folder page, inside a folder") {
    NavigationStack {
        KitchenFolderPage(
            path: ["Baking"],
            presenter: KitchenFeaturePresenterStub(),
            viewModel: previewViewModel()
        )
        .navigationTitle("Baking")
    }
}
