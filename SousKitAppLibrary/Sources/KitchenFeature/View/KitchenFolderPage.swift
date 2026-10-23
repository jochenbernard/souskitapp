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
        // A blank page, rather than a list and a search field the restored screens cover a moment later.
        if viewModel.isRestoring {
            Color.clear
                .sousPage()
        } else {
            ScrollView {
                folderContents
                    .sousPagePadding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            // Over the page rather than in it, so it stays centered in what the field and the keyboard leave visible.
            .overlay {
                if let emptySearch {
                    emptySearchNote(emptySearch)
                }
            }
            .sousPage()
            .searchable(text: searchText, prompt: searchPrompt)
        }
    }

    /// The text of a search that found nothing among the recipes listed, or `nil` where none did.
    private var emptySearch: String? {
        guard
            case .recipes = viewModel.recipeList,
            let search = viewModel.searches[path],
            search.isSearching,
            search.results.isEmpty
        else {
            return nil
        }

        return search.text
    }

    @ViewBuilder
    private var folderContents: some View {
        switch viewModel.recipeList {
        case .reading:
            readingNote

        case .recipes(let topFolder):
            if let search = viewModel.searches[path], search.isSearching {
                searchResultsView(search.results)
            } else if let folder = topFolder.folder(at: path), !folder.isEmpty {
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

    private func searchResultsView(_ cards: [KitchenRecipeCard]) -> some View {
        RecipeCardGrid(minimumColumnWidth: minimumColumnWidth, spacing: SousSpacing.medium) {
            ForEach(cards) { card in
                Button(
                    action: { presenter.didPush(.recipe(card.recipeEntry), from: origin) },
                    label: { RecipeCard(card, detail: .folder(folderNames(of: card))) }
                )
                .buttonStyle(.plain)
            }
        }
    }

    private var minimumColumnWidth: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? scaledCardWidth : Self.minimumCardWidth
    }

    /// The screen showing the folder, which its cards push over.
    private var origin: KitchenScreen? {
        path.isEmpty ? nil : .folder(path)
    }

    /// Where a recipe a search found sits: from the repository's name down at the top, and from the folder searched
    /// down inside one, which a recipe directly in it shows by that folder's name.
    private func folderNames(of card: KitchenRecipeCard) -> [String] {
        guard let folderName = path.last else {
            return [viewModel.recipeRepositoryName] + card.recipeEntry.folderPath
        }

        let innerNames = Array(card.recipeEntry.folderPath.dropFirst(path.count))

        return innerNames.isEmpty ? [folderName] : innerNames
    }

    private func folderView(_ folder: KitchenFolder) -> some View {
        RecipeCardGrid(minimumColumnWidth: minimumColumnWidth, spacing: SousSpacing.medium) {
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

    private func emptySearchNote(_ text: String) -> some View {
        // Smaller text where the keyboard leaves too little room, rather than a scroll view the large title follows.
        ViewThatFits(in: .vertical) {
            ContentUnavailableView.search(text: text)

            ContentUnavailableView.search(text: text)
                .dynamicTypeSize(...DynamicTypeSize.accessibility1)

            ContentUnavailableView.search(text: text)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
    }

    private var searchText: Binding<String> {
        Binding(
            get: { viewModel.searches[path]?.text ?? "" },
            set: { text in presenter.didChangeSearchText(text, in: path) }
        )
    }

    private var searchPrompt: Text {
        guard let folderName = path.last else {
            return Text("Search recipes", bundle: .module)
        }

        return Text("Search in \(folderName)", bundle: .module)
    }
}

/// A recipe at `path`, its folders and file name separated by slashes.
private func previewEntry(_ path: String) -> RecipeEntry {
    let components = path.split(separator: "/").map(String.init)

    return RecipeEntry(
        id: path,
        name: components.last ?? path,
        availability: .downloaded,
        folderPath: Array(components.dropLast())
    )
}

@MainActor
private func previewViewModel() -> KitchenFeatureViewModel {
    let viewModel = KitchenFeatureViewModel(recipeRepositoryName: "Recipes")
    let entries = ["Baking/brioche", "Baking/madeleines", "Baking/Classic/crepes", "vinaigrette"].map(previewEntry)
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

/// A search for `text` on the folder page at `path`, finding the recipes at `recipePaths`.
@MainActor
private func previewSearch(
    _ text: String,
    at path: [String],
    finding recipePaths: [String]
) -> KitchenFeatureViewModel {
    let viewModel = previewViewModel()
    let results = recipePaths.map({ KitchenFeaturePresenter.card(for: previewEntry($0)) })
    viewModel.searches[path] = KitchenSearch(text: text, isSearching: true, results: results)

    return viewModel
}

#Preview("Folder page, search results") {
    NavigationStack {
        KitchenFolderPage(
            path: [],
            presenter: KitchenFeaturePresenterStub(),
            viewModel: previewSearch("b", at: [], finding: ["Baking/brioche", "Baking/Classic/crepes"])
        )
        .navigationTitle("Recipes")
    }
}

#Preview("Folder page, search results inside a folder") {
    NavigationStack {
        KitchenFolderPage(
            path: ["Baking"],
            presenter: KitchenFeaturePresenterStub(),
            viewModel: previewSearch("b", at: ["Baking"], finding: ["Baking/brioche", "Baking/Classic/crepes"])
        )
        .navigationTitle("Baking")
    }
}

#Preview("Folder page, no search results") {
    NavigationStack {
        KitchenFolderPage(
            path: [],
            presenter: KitchenFeaturePresenterStub(),
            viewModel: previewSearch("mussels", at: [], finding: [])
        )
        .navigationTitle("Recipes")
    }
}
