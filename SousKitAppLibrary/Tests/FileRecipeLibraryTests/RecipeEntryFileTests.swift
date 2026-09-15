@testable import FileRecipeLibrary
import RecipeLibrary
import Testing

@Suite("Recipe entry for a file")
struct RecipeEntryFileTests {
    private func recipeEntry(named fileName: String) -> RecipeEntry {
        RecipeEntry(fileName: fileName, availability: .downloaded)
    }

    @Test("hyphens part the words of a name")
    func hyphenatedName() {
        #expect(recipeEntry(named: "boeuf-bourguignon.sous").name == "boeuf bourguignon")
    }

    @Test("underscores part the words of a name")
    func underscoredName() {
        #expect(recipeEntry(named: "creme_brulee.sous").name == "creme brulee")
    }

    @Test("spaces part the words of a name")
    func spacedName() {
        #expect(recipeEntry(named: "quiche lorraine.sous").name == "quiche lorraine")
    }

    @Test("the name keeps the file's own casing")
    func casingInName() {
        #expect(recipeEntry(named: "Crepes.sous").name == "Crepes")
    }

    @Test("a word in capitals keeps them")
    func innerCapitalsInName() {
        #expect(recipeEntry(named: "pain-de-MIE.sous").name == "pain de MIE")
    }

    @Test("repeated separators make one space")
    func repeatedSeparatorsInName() {
        #expect(recipeEntry(named: "gratin--dauphinois.sous").name == "gratin dauphinois")
    }

    @Test("only the last extension comes off the name")
    func innerDotsInName() {
        #expect(recipeEntry(named: "crepes.v2.sous").name == "crepes.v2")
    }

    @Test("an extension in capitals comes off the name too")
    func capitalizedExtensionInName() {
        #expect(recipeEntry(named: "VINAIGRETTE.SOUS").name == "VINAIGRETTE")
    }

    @Test("the file name keeps its extension")
    func fileName() {
        #expect(recipeEntry(named: "boeuf-bourguignon.sous").fileName == "boeuf-bourguignon.sous")
    }

    @Test("the identifier is the file name")
    func identifier() {
        let entry = recipeEntry(named: "crepes.sous")
        #expect(entry.id == entry.fileName)
    }
}
