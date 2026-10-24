import RecipeLibrary
import SousKit
import Testing

@Suite("Recipe summary image path")
struct RecipeSummaryImagePathTests {
    private let parser = SousParser()

    /// Where the picture named by a header's `image` value sits, for a recipe in the given folder.
    private func imagePath(_ value: String?, inFolder folderPath: [String] = []) -> String? {
        let imageLine = value.map({ "image: \($0)\n" }) ?? ""
        let header = "---\ntitle: Gratin Dauphinois\n\(imageLine)---"
        let summary = RecipeSummary(recipe: parser.parseRecipe(header).value, parser: parser)

        return summary.imagePath(inFolder: folderPath)
    }

    @Test("a relative path is read from the recipe's folder")
    func relative() {
        #expect(imagePath("images/gratin-dauphinois.jpg") == "images/gratin-dauphinois.jpg")
        #expect(imagePath("gratin-dauphinois.jpg", inFolder: ["French"]) == "French/gratin-dauphinois.jpg")
    }

    @Test("a path in a recipe nested in folders leads down from the innermost")
    func nested() {
        #expect(
            imagePath("images/gratin-dauphinois.jpg", inFolder: ["French", "Comfort food"])
                == "French/Comfort food/images/gratin-dauphinois.jpg"
        )
    }

    @Test("a path climbing out of the recipe's folder counts while it stays inside the repository")
    func parentInside() {
        #expect(imagePath("../images/crepes.jpg", inFolder: ["Baking"]) == "images/crepes.jpg")
        #expect(
            imagePath("../../images/bouillabaisse.jpg", inFolder: ["Dinner", "Provencal"]) == "images/bouillabaisse.jpg"
        )
        #expect(imagePath("./images/../brioche.jpg", inFolder: ["Baking"]) == "Baking/brioche.jpg")
    }

    @Test("a path climbing above the repository's top names no picture")
    func parentOutside() {
        #expect(imagePath("../images/crepes.jpg") == nil)
        #expect(imagePath("../../images/bouillabaisse.jpg", inFolder: ["Dinner"]) == nil)
        #expect(imagePath("images/../../crepes.jpg") == nil)
    }

    @Test("an absolute path names no picture")
    func absolute() {
        #expect(imagePath("/images/moules-marinieres.jpg") == nil)
        #expect(imagePath("/images/moules-marinieres.jpg", inFolder: ["Dinner"]) == nil)
    }

    @Test("a web address or any other URL names no picture")
    func url() {
        #expect(imagePath("https://example.com/quiche-lorraine.jpg") == nil)
        #expect(imagePath("http://example.com/quiche-lorraine.jpg") == nil)
        #expect(imagePath("file:///images/quiche-lorraine.jpg") == nil)
        #expect(imagePath("data:image/png;base64,AAAA") == nil)
        #expect(imagePath(#"C:\x"#) == nil)
    }

    @Test("a header naming no picture, or an empty one, names none")
    func missing() {
        #expect(imagePath(nil) == nil)
        #expect(imagePath("") == nil)
        #expect(imagePath("..", inFolder: ["Baking"]) == nil)
    }

    @Test("a colon inside a path is part of a name, not a scheme")
    func colonInName() {
        #expect(imagePath("images/a:b.jpg") == "images/a:b.jpg")
    }
}
