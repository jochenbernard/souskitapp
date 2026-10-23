@testable import KitchenFeature
import RecipeLibrary
import Testing

@Suite("Kitchen folder tree")
struct KitchenFolderTreeTests {
    private func top(holding paths: [String]) -> KitchenFolder {
        KitchenFolderTree.folder(at: [], holding: paths.map(RecipeEntry.stubbed(at:)))
    }

    @Test("recipes at the top are its cards, and each folder holds its own")
    func topAndFolders() {
        let folder = top(holding: ["crepes", "Baking/brioche", "Baking/madeleines"])

        #expect(folder.cards.map(\.id) == ["crepes"])
        #expect(folder.folders.map(\.path) == [["Baking"]])
        #expect(folder.folders.first?.cards.map(\.id) == ["Baking/brioche", "Baking/madeleines"])
    }

    @Test("a folder holding only folders lists them and no cards")
    func folderOfFolders() throws {
        let folder = top(holding: ["French/Classic/quiche-lorraine", "French/Comfort food/gratin-dauphinois"])
        let french = try #require(folder.folder(at: ["French"]))

        #expect(folder.cards.isEmpty)
        #expect(french.cards.isEmpty)
        #expect(french.folders.map(\.name) == ["Classic", "Comfort food"])
        #expect(!french.isEmpty)
    }

    @Test("folders nest at any depth, each found by the names leading down to it")
    func depth() throws {
        let folder = top(holding: ["Dinner/French/Provencal/Classic/bouillabaisse"])

        let deepest = try #require(folder.folder(at: ["Dinner", "French", "Provencal", "Classic"]))

        #expect(deepest.cards.map(\.id) == ["Dinner/French/Provencal/Classic/bouillabaisse"])
        #expect(deepest.name == "Classic")
    }

    @Test("folders are ordered by name, numbers by value")
    func folderOrder() {
        let folder = top(
            holding: ["lunch/croque-monsieur", "Baking 10/brioche", "Baking 2/madeleines", "dinner/brioche"]
        )

        #expect(folder.folders.map(\.name) == ["Baking 2", "Baking 10", "dinner", "lunch"])
    }

    @Test("recipes sharing a file name in two folders are two cards, one in each")
    func sameFileNameInTwoFolders() {
        let folder = top(holding: ["vinaigrette", "Sauce/vinaigrette"])

        #expect(folder.cards.map(\.id) == ["vinaigrette"])
        #expect(folder.folder(at: ["Sauce"])?.cards.map(\.id) == ["Sauce/vinaigrette"])
    }

    @Test("a folder no longer listed is not found")
    func missingFolder() {
        let folder = top(holding: ["Baking/brioche"])

        #expect(folder.folder(at: ["Dinner"]) == nil)
        #expect(folder.folder(at: ["Baking", "Classic"]) == nil)
        #expect(folder.folder(at: []) == folder)
    }

    @Test("no recipes make an empty top")
    func empty() {
        #expect(top(holding: []).isEmpty)
    }

    @Test("a folder counts the recipes anywhere below it")
    func recipeCount() throws {
        let folder = top(holding: ["crepes", "French/Classic/quiche-lorraine", "French/Comfort food/gratin-dauphinois"])

        #expect(folder.recipeCount == 3)
        #expect(try #require(folder.folder(at: ["French"])).recipeCount == 2)
        #expect(try #require(folder.folder(at: ["French", "Classic"])).recipeCount == 1)
    }

    @Test("a folder stacks its own recipes first, then those in the folders inside it, four at most")
    func stackedCards() throws {
        let folder = top(
            holding: [
                "Baking/Classic/brioche",
                "Baking/crepes",
                "Baking/madeleines",
                "Baking/Comfort food/gratin-dauphinois",
                "Baking/Classic/croque-monsieur"
            ]
        )
        let baking = try #require(folder.folder(at: ["Baking"]))

        #expect(
            baking.stackedCards.map(\.id) == [
                "Baking/crepes",
                "Baking/madeleines",
                "Baking/Classic/brioche",
                "Baking/Classic/croque-monsieur"
            ]
        )
    }

    @Test("a folder of one recipe stacks one card, and a folder of only folders stacks the recipes below it")
    func shortStacks() throws {
        let folder = top(holding: ["French/Classic/quiche-lorraine", "French/Comfort food/gratin-dauphinois"])

        #expect(try #require(folder.folder(at: ["French", "Classic"])).stackedCards.map(\.id) == [
            "French/Classic/quiche-lorraine"
        ])
        #expect(try #require(folder.folder(at: ["French"])).stackedCards.map(\.id) == [
            "French/Classic/quiche-lorraine",
            "French/Comfort food/gratin-dauphinois"
        ])
    }
}
