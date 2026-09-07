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

    @Test("the path carries no percent escapes")
    func path() {
        let directory = RecipeDirectory(url: URL(filePath: "/Users/cook/My Recipes"))
        #expect(directory.path == "/Users/cook/My Recipes")
    }

    @Test("a trailing slash leaves the name alone")
    func trailingSlashInName() {
        let directory = RecipeDirectory(url: URL(filePath: "/Users/cook/Recipes/"))
        #expect(directory.name == "Recipes")
    }

    @Test("a trailing slash is taken off the path")
    func trailingSlashInPath() {
        let directory = RecipeDirectory(url: URL(filePath: "/Users/cook/Recipes/"))
        #expect(directory.path == "/Users/cook/Recipes")
    }

    @Test("the root path keeps its one separator")
    func rootPath() {
        let directory = RecipeDirectory(url: URL(filePath: "/"))
        #expect(directory.path == "/")
    }
}
