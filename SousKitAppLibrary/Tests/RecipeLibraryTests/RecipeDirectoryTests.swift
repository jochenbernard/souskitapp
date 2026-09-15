import Foundation
import RecipeLibrary
import Testing

@Suite("Recipe directory")
struct RecipeDirectoryTests {
    @Test("the name is the last path component")
    func name() {
        let directory = RecipeDirectory(url: URL(filePath: "/Users/cook/Documents/Recipes"))
        #expect(directory.name == "Recipes")
    }

    @Test("a trailing slash leaves the name alone")
    func trailingSlashInName() {
        let directory = RecipeDirectory(url: URL(filePath: "/Users/cook/Recipes/"))
        #expect(directory.name == "Recipes")
    }
}
