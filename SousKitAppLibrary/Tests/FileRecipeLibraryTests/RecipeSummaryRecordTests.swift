@testable import FileRecipeLibrary
import Foundation
import RecipeLibrary
import SousKit
import Testing

@Suite("Recipe summary record")
struct RecipeSummaryRecordTests {
    private let parser = SousParser()
    private let date = Date(timeIntervalSinceReferenceDate: 800_000_000.0)

    private func record(of text: String) -> RecipeSummaryRecord {
        RecipeSummaryRecord(recipe: parser.parseRecipe(text).value, modificationDate: date)
    }

    private func file(
        _ availability: RecipeAvailability,
        modifiedAt modificationDate: Date?,
        isOutdated: Bool = false
    ) -> RecipeFile {
        RecipeFile(
            path: "crepes.sous",
            availability: availability,
            modificationDate: modificationDate,
            isOutdated: isOutdated
        )
    }

    @Test(
        "a header reads back as the metadata it was kept from",
        arguments: [
            "---\ntitle: Crepes\nservings: 4\ntags: [dessert, classic, french]\n---\n\nWhisk @{200 g} flour@.",
            """
            ---
            title: Vinaigrette
            stray line
            chef: Camille
            chef: Bruno
            : Camille
            tags: [french]
            tags: [quick]
            servings: 3,2
            yield: [6 servings, 0 g]
            ---
            """,
            "---\ntitle: Vinaigrette\nyield: [125 ml]\n\nWhisk @{1 tsp} dijon mustard@.",
            "Whisk @{1 tsp} dijon mustard@ into @{2 tbsp} red wine vinegar@.",
            ""
        ]
    )
    func headerRoundTrip(text: String) {
        let summary = record(of: text).summary(parsedWith: parser)

        #expect(summary.metadata == parser.parseRecipe(text).value.metadata)
    }

    @Test("the ingredient names are kept, each once")
    func ingredientNames() {
        let kept = record(of: "Soften @{2 cloves} garlic@ in @{2 tbsp} olive oil@, then add @{1 clove} garlic@.")

        #expect(kept.ingredientNames == ["garlic", "olive oil"])
    }

    @Test("a file modified at the date kept is unchanged")
    func sameDate() {
        #expect(record(of: "").isCurrent(for: file(.downloaded, modifiedAt: date)))
        #expect(record(of: "").isCurrent(for: file(.notDownloaded, modifiedAt: date)))
    }

    @Test("a file modified at another date has changed, on the device or in iCloud")
    func otherDate() {
        let later = date.addingTimeInterval(60.0)

        #expect(!record(of: "").isCurrent(for: file(.downloaded, modifiedAt: later)))
        #expect(!record(of: "").isCurrent(for: file(.notDownloaded, modifiedAt: later)))
        #expect(!record(of: "").isCurrent(for: file(.downloading, modifiedAt: later)))
    }

    @Test("a placeholder telling no date has changed, so it is fetched")
    func placeholderWithoutDate() {
        #expect(!record(of: "").isCurrent(for: file(.notDownloaded, modifiedAt: nil)))
        #expect(!record(of: "").isCurrent(for: file(.downloading, modifiedAt: nil)))
    }

    @Test("a file on the device telling no date is read again")
    func downloadedWithoutDate() {
        #expect(!record(of: "").isCurrent(for: file(.downloaded, modifiedAt: nil)))
    }

    @Test("a file outdated on the device has changed, though its date is the one kept")
    func outdated() {
        #expect(!record(of: "").isCurrent(for: file(.downloading, modifiedAt: date, isOutdated: true)))
    }
}
