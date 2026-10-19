import RecipeLibrary
import SousKit

/// The words a search finds one recipe by, in the form they are matched in.
struct RecipeSearchTerms {
    private let titleWords: [String]
    private let tagWords: [String]
    private let ingredientWords: [String]

    /// Creates the terms of a recipe as it is listed, from its summary alone.
    ///
    /// - Parameter listedRecipe: The recipe.
    init(_ listedRecipe: ListedRecipe) {
        self.titleWords = Self.words(of: listedRecipe.entry.title)
        self.tagWords = (listedRecipe.entry.summary?.metadata.tags ?? []).flatMap(Self.words(of:))
        self.ingredientWords = listedRecipe.ingredientNames.flatMap(Self.words(of:))
    }

    /// Where the recipe matches every word searched for, each beginning a word of its title, a tag or an
    /// ingredient's name.
    ///
    /// - Parameter queryWords: The words searched for, from ``words(of:)``.
    /// - Returns: The match, or `nil` where a word matches nowhere or none is searched for.
    func match(_ queryWords: [String]) -> RecipeSearchMatch? {
        guard !queryWords.isEmpty else {
            return nil
        }

        var loosest = RecipeSearchMatch.title

        for queryWord in queryWords {
            guard let match = closestMatch(of: queryWord) else {
                return nil
            }

            loosest = max(loosest, match)
        }

        return loosest
    }

    /// The words of a text in the form they are matched in: split at whatever is not a letter or a digit, and
    /// folded the way Sous matches names, ignoring case and accents.
    ///
    /// - Parameter text: The text.
    /// - Returns: The words, in the order written.
    static func words(of text: String) -> [String] {
        Normalization.normalized(text)
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
    }

    private func closestMatch(of queryWord: String) -> RecipeSearchMatch? {
        if titleWords.contains(where: { $0.hasPrefix(queryWord) }) {
            return .title
        }

        if tagWords.contains(where: { $0.hasPrefix(queryWord) }) {
            return .tag
        }

        if ingredientWords.contains(where: { $0.hasPrefix(queryWord) }) {
            return .ingredient
        }

        return nil
    }
}
