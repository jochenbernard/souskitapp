import RecipeLibrary
import SousKit
import Testing

@Suite("Recipe entry title")
struct RecipeEntryTitleTests {
    private let parser = SousParser()
    private let entry = RecipeEntry(
        id: "vinaigrette.sous",
        name: "vinaigrette",
        availability: .downloaded
    )

    @Test("a recipe with a title shows it")
    func titledRecipe() {
        let recipe = parser.parseRecipe("---\ntitle: Vinaigrette\n---\nWhisk it.").value

        #expect(entry.title(of: recipe) == "Vinaigrette")
    }

    @Test("a recipe without a title shows the entry's name")
    func untitledRecipe() {
        let recipe = parser.parseRecipe("Whisk it.").value

        #expect(entry.title(of: recipe) == "vinaigrette")
    }

    @Test("a recipe with an empty title shows the entry's name")
    func emptyTitle() {
        let recipe = parser.parseRecipe("---\ntitle:\n---\nWhisk it.").value

        #expect(entry.title(of: recipe) == "vinaigrette")
    }
}
