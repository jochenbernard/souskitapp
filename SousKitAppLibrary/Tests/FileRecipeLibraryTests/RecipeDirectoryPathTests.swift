@testable import FileRecipeLibrary
import Foundation
import Testing

@Suite("Recipe directory paths")
struct RecipeDirectoryPathTests {
    private let directory = RecipeDirectory(url: URL(filePath: "/Recipes", directoryHint: .isDirectory))

    @Test("a file at the top of the directory is found by its name")
    func topFile() {
        #expect(directory.path(ofFileAt: URL(filePath: "/Recipes/crepes.sous")) == "crepes.sous")
    }

    @Test("a file in a folder of the directory is found by the folders leading down to it")
    func nestedFile() {
        let url = URL(filePath: "/Recipes/French/Classic/quiche-lorraine.sous")

        #expect(directory.path(ofFileAt: url) == "French/Classic/quiche-lorraine.sous")
    }

    @Test("a file outside the directory has no path in it")
    func outsideFile() {
        #expect(directory.path(ofFileAt: URL(filePath: "/Downloads/vinaigrette.sous")) == nil)
    }

    @Test("a file in a sibling whose name starts with the directory's has no path in it")
    func siblingWithSharedPrefix() {
        #expect(directory.path(ofFileAt: URL(filePath: "/Recipes Old/crepes.sous")) == nil)
    }

    @Test("the directory itself has no path in it")
    func directoryItself() {
        #expect(directory.path(ofFileAt: URL(filePath: "/Recipes", directoryHint: .isDirectory)) == nil)
    }
}
