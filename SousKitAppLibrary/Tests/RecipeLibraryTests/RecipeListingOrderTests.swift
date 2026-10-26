import RecipeLibrary
import SousKit
import Testing

@Suite("Recipe listing order")
struct RecipeListingOrderTests {
    private let parser = SousParser()

    /// A recipe in a file of its own name, titled in its header, with the picture of its file's name where it has one.
    private func entry(
        _ fileName: String,
        titled title: String,
        in folderPath: [String] = [],
        hasPicture: Bool = true
    ) -> RecipeEntry {
        let path = (folderPath + [fileName]).joined(separator: "/")
        let recipe = parser.parseRecipe("---\ntitle: \(title)\n---\nBake it.").value
        let picture = RecipePicture(
            id: "\(path).jpg",
            modificationDate: nil,
            availability: .downloaded
        )

        return RecipeEntry(
            id: "\(path).sous",
            name: fileName,
            availability: .downloaded,
            summary: RecipeSummary(recipe: recipe, parser: parser),
            folderPath: folderPath,
            picture: hasPicture ? picture : nil
        )
    }

    @Test("recipes are listed by title, whatever their files are named, and folders by name, numbers by value")
    func order() {
        let entries = [entry("a", titled: "Crepes"), entry("b", titled: "Brioche"), entry("c", titled: "Brioche")]
        let folderNames = ["Lunch", "Baking 10", "Baking 2"]

        #expect(entries.sorted(by: RecipeListingOrder.isOrderedBefore).map(\.id) == ["b.sous", "c.sous", "a.sous"])
        #expect(folderNames.sorted(by: RecipeListingOrder.isOrderedBefore) == ["Baking 2", "Baking 10", "Lunch"])
    }

    @Test("the pictures shown first are those of the recipes each folder is shown by, then those at the top, by title")
    func firstPictures() {
        let entries = [
            entry("a1", titled: "Moules Marinieres"),
            entry("a2", titled: "Gratin Dauphinois"),
            entry("b1", titled: "Quiche Lorraine", in: ["Baking"]),
            entry("b2", titled: "Crepes", in: ["Baking"]),
            entry("b3", titled: "Madeleines", in: ["Baking"]),
            entry("b4", titled: "Brioche", in: ["Baking"], hasPicture: false),
            entry("b5", titled: "Bouillabaisse", in: ["Baking"]),
            entry("b6", titled: "Vinaigrette", in: ["Baking"]),
            entry("c1", titled: "Brioche", in: ["Baking", "Breads"]),
            entry("d1", titled: "Boeuf Bourguignon", in: ["Lunch", "Toasts"]),
            entry("d2", titled: "Croque Monsieur", in: ["Lunch"])
        ]

        let pictures = RecipeListingOrder.firstPictures(of: entries)

        // Baking's recipe with no picture still takes one of its four places; Lunch's own come before Toasts'.
        #expect(
            pictures.map(\.id) == [
                "Baking/b5.jpg",
                "Baking/b2.jpg",
                "Baking/b3.jpg",
                "Lunch/d2.jpg",
                "Lunch/Toasts/d1.jpg",
                "a2.jpg",
                "a1.jpg"
            ]
        )
    }

    @Test("at most 24 pictures are shown first")
    func firstPictureLimit() {
        let entries = (1...30).map({ entry("crepes-\($0)", titled: "Crepes \(31 - $0)") })

        let pictures = RecipeListingOrder.firstPictures(of: entries)

        #expect(pictures.map(\.id) == (7...30).reversed().map({ "crepes-\($0).jpg" }))
    }
}
