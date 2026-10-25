import DesignSystem
import RecipeLibrary
import SwiftUI

/// What a folder of the repository holds, as the kitchen's top screen or a screen pushed for the folder shows it:
/// the folders inside it and its recipes, as cards.
struct KitchenFolderPage: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @ScaledMetric(relativeTo: .body) private var scaledCardWidth = Self.minimumCardWidth

    @State private var pageSize = CGSize.zero

    // Two columns on any iPhone; at accessibility sizes the width grows with the text, which leaves the iPhone one.
    private static let minimumCardWidth = 160.0

    private static let maximumPreviewWidth = 370.0
    // The iPad crops a preview wider than about 330 points and narrows one taller than about 490 points.
    private static let regularPreviewSize = CGSize(width: 320.0, height: 488.0)
    // On an iPhone a preview leaves room for the menu under it.
    private static let menuRoom = 330.0

    // The names of the folders leading down to the folder, or none for the top of the repository.
    private let path: [String]
    private let presenter: KitchenFeaturePresenterProtocol
    private let viewModel: KitchenFeatureViewModel
    private let cardTransition: Namespace.ID

    /// - Parameter cardTransition: Where a recipe the page pushes zooms out of its card, by the recipe's id.
    init(
        path: [String],
        presenter: KitchenFeaturePresenterProtocol,
        viewModel: KitchenFeatureViewModel,
        cardTransition: Namespace.ID
    ) {
        self.path = path
        self.presenter = presenter
        self.viewModel = viewModel
        self.cardTransition = cardTransition
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
            // With the bars, which a preview may cover.
            .onGeometryChange(
                for: CGSize.self,
                of: { proxy in
                    CGSize(
                        width: proxy.size.width,
                        height: proxy.size.height + proxy.safeAreaInsets.top + proxy.safeAreaInsets.bottom
                    )
                },
                action: { pageSize = $0 }
            )
            // Over the page rather than in it, so it stays centered in what the field and the keyboard leave visible.
            .overlay {
                if let emptySearch {
                    emptySearchNote(emptySearch)
                }
            }
            .sousPage()
            .searchable(
                text: searchText,
                isPresented: isSearchPresented,
                prompt: searchPrompt
            )
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
                recipeButton(card, detail: .folder(folderNames(of: card)))
            }
        }
    }

    private var minimumColumnWidth: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? scaledCardWidth : Self.minimumCardWidth
    }

    private func recipeButton(_ card: KitchenRecipeCard, detail: RecipeCard.Detail) -> some View {
        RecipeCardButton(
            card,
            detail: detail,
            folderPath: path,
            presenter: presenter,
            viewModel: viewModel,
            cardTransition: cardTransition,
            previewSize: previewSize
        )
    }

    /// The most a card's preview takes of the page: its width, and its height, which leaves room for the menu.
    private var previewSize: CGSize {
        switch horizontalSizeClass {
        case .regular:
            return Self.regularPreviewSize

        case .compact, nil:
            let width = min(Self.maximumPreviewWidth, pageSize.width - SousSpacing.large * 2.0)

            return CGSize(width: width, height: max(pageSize.height - Self.menuRoom, width))

        @unknown default:
            return Self.regularPreviewSize
        }
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
                FolderCardButton(
                    innerFolder,
                    origin: origin,
                    presenter: presenter,
                    viewModel: viewModel,
                    previewSize: previewSize
                )
            }

            ForEach(folder.cards) { card in
                recipeButton(card, detail: .totalTime)
            }
        }
    }

    /// The screen showing the folder, which its cards push over.
    private var origin: KitchenScreen? {
        path.isEmpty ? nil : .folder(path)
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

    private var isSearchPresented: Binding<Bool> {
        Binding(
            get: { viewModel.presentedSearchPath == path },
            set: { isPresented in presenter.didChangeIsSearchPresented(isPresented, in: path) }
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
    @Previewable @Namespace var cardTransition

    NavigationStack {
        KitchenFolderPage(
            path: [],
            presenter: KitchenFeaturePresenterStub(),
            viewModel: previewViewModel(),
            cardTransition: cardTransition
        )
        .navigationTitle("Recipes")
    }
}

#Preview("Folder page, inside a folder") {
    @Previewable @Namespace var cardTransition

    NavigationStack {
        KitchenFolderPage(
            path: ["Baking"],
            presenter: KitchenFeaturePresenterStub(),
            viewModel: previewViewModel(),
            cardTransition: cardTransition
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
    let results = recipePaths.map({ KitchenRecipeCard(recipeEntry: previewEntry($0)) })
    viewModel.searches[path] = KitchenSearch(text: text, isSearching: true, results: results)

    return viewModel
}

#Preview("Folder page, search results") {
    @Previewable @Namespace var cardTransition

    NavigationStack {
        KitchenFolderPage(
            path: [],
            presenter: KitchenFeaturePresenterStub(),
            viewModel: previewSearch("b", at: [], finding: ["Baking/brioche", "Baking/Classic/crepes"]),
            cardTransition: cardTransition
        )
        .navigationTitle("Recipes")
    }
}

#Preview("Folder page, search results inside a folder") {
    @Previewable @Namespace var cardTransition

    NavigationStack {
        KitchenFolderPage(
            path: ["Baking"],
            presenter: KitchenFeaturePresenterStub(),
            viewModel: previewSearch("b", at: ["Baking"], finding: ["Baking/brioche", "Baking/Classic/crepes"]),
            cardTransition: cardTransition
        )
        .navigationTitle("Baking")
    }
}

#Preview("Folder page, no search results") {
    @Previewable @Namespace var cardTransition

    NavigationStack {
        KitchenFolderPage(
            path: [],
            presenter: KitchenFeaturePresenterStub(),
            viewModel: previewSearch("mussels", at: [], finding: []),
            cardTransition: cardTransition
        )
        .navigationTitle("Recipes")
    }
}
