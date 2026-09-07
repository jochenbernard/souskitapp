import Foundation
import RecipeLibrary
import Testing

@Suite("Recipe file")
struct RecipeFileTests {
    private func recipeFile(named fileName: String) -> RecipeFile {
        RecipeFile(
            url: URL(filePath: "/Users/cook/Recipes").appending(path: fileName),
            availability: .downloaded
        )
    }

    @Test("hyphens part the words of a name")
    func hyphenatedName() {
        #expect(recipeFile(named: "boeuf-bourguignon.sous").name == "Boeuf Bourguignon")
    }

    @Test("underscores part the words of a name")
    func underscoredName() {
        #expect(recipeFile(named: "creme_brulee.sous").name == "Creme Brulee")
    }

    @Test("spaces part the words of a name")
    func spacedName() {
        #expect(recipeFile(named: "quiche lorraine.sous").name == "Quiche Lorraine")
    }

    @Test("a capital already there is left alone")
    func capitalizedName() {
        #expect(recipeFile(named: "Crepes.sous").name == "Crepes")
    }

    @Test("only the first character of a word is raised")
    func innerCapitalsInName() {
        #expect(recipeFile(named: "pain-de-MIE.sous").name == "Pain De MIE")
    }

    @Test("repeated separators make one space")
    func repeatedSeparatorsInName() {
        #expect(recipeFile(named: "gratin--dauphinois.sous").name == "Gratin Dauphinois")
    }

    @Test("only the last extension comes off the name")
    func innerDotsInName() {
        #expect(recipeFile(named: "crepes.v2.sous").name == "Crepes.v2")
    }

    @Test("an extension in capitals comes off the name too")
    func capitalizedExtensionInName() {
        #expect(recipeFile(named: "VINAIGRETTE.SOUS").name == "VINAIGRETTE")
    }

    @Test("the file name keeps its extension")
    func fileName() {
        #expect(recipeFile(named: "boeuf-bourguignon.sous").fileName == "boeuf-bourguignon.sous")
    }

    @Test("the identifier is where the file sits")
    func identifier() {
        let file = recipeFile(named: "crepes.sous")
        #expect(file.id == file.url)
    }
}
