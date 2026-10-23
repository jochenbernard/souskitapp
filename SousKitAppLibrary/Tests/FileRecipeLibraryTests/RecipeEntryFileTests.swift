@testable import FileRecipeLibrary
import RecipeLibrary
import Testing

@Suite("Recipe entry for a file")
struct RecipeEntryFileTests {
    private func recipeEntry(named fileName: String) -> RecipeEntry {
        RecipeEntry(path: fileName, availability: .downloaded)
    }

    @Test("hyphens part the words of a name")
    func hyphenatedName() {
        #expect(recipeEntry(named: "boeuf-bourguignon.sous").name == "boeuf bourguignon")
    }

    @Test("underscores part the words of a name")
    func underscoredName() {
        #expect(recipeEntry(named: "moules_marinieres.sous").name == "moules marinieres")
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

    @Test("the path keeps its extension")
    func path() {
        #expect(recipeEntry(named: "boeuf-bourguignon.sous").path == "boeuf-bourguignon.sous")
    }

    @Test("a recipe at the top of the directory sits in no folder")
    func topFolderPath() {
        #expect(recipeEntry(named: "crepes.sous").folderPath.isEmpty)
    }

    @Test("a recipe in a directory inside sits in the folders leading down to it, and is named after its file")
    func nestedFolderPath() {
        let recipeEntry = recipeEntry(named: "French/Comfort food/gratin-dauphinois.sous")

        #expect(recipeEntry.folderPath == ["French", "Comfort food"])
        #expect(recipeEntry.name == "gratin dauphinois")
        #expect(recipeEntry.id == "French/Comfort food/gratin-dauphinois.sous")
    }

    @Test("files sharing a name in different directories are different recipes")
    func sameFileNameInTwoFolders() {
        let top = recipeEntry(named: "vinaigrette.sous")
        let nested = recipeEntry(named: "Sauce/vinaigrette.sous")

        #expect(top.name == nested.name)
        #expect(top.id != nested.id)
    }
}
