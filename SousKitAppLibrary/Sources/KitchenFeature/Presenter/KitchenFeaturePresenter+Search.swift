import RecipeLibrary

extension KitchenFeaturePresenter {
    @MainActor
    func didChangeSearchText(_ text: String, in folderPath: [String]) {
        viewModel.searches[folderPath] = text.isEmpty ? nil : search(for: text, below: folderPath)
    }

    /// Searches every folder screen's text again, in the recipes as they are listed now.
    @MainActor
    func showSearchResults() {
        guard !viewModel.searches.isEmpty else {
            return
        }

        viewModel.searches = Dictionary(
            uniqueKeysWithValues: viewModel.searches.map({ ($0.key, search(for: $0.value.text, below: $0.key)) })
        )
    }

    /// What a search for the text finds in a folder and the folders below it, from the summaries listed alone.
    @MainActor
    func search(for text: String, below folderPath: [String]) -> KitchenSearch {
        let queryWords = RecipeSearchTerms.words(of: text)

        return KitchenSearch(
            text: text,
            isSearching: !queryWords.isEmpty,
            results: searchIndex.results(matching: queryWords, below: folderPath).map(Self.card(for:))
        )
    }

    /// Forgets what was searched on folder screens no longer on the stack, so a folder pushed again opens unsearched.
    @MainActor
    func forgetSearches(offScreen pushedScreens: [KitchenScreen]) {
        let searches = viewModel.searches.filter { folderPath, _ in
            folderPath.isEmpty || pushedScreens.contains(.folder(folderPath))
        }

        if searches.count != viewModel.searches.count {
            viewModel.searches = searches
        }
    }
}
