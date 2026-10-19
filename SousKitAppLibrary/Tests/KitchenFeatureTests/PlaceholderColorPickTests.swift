import DesignSystem
@testable import KitchenFeature
import Testing

@Suite("Placeholder color pick")
struct PlaceholderColorPickTests {
    @Test("the hash is FNV-1a, which gives the same value on every launch")
    func knownHashes() {
        #expect(PlaceholderColorPick.fnv1a("") == 0xCBF2_9CE4_8422_2325)
        #expect(PlaceholderColorPick.fnv1a("a") == 0xAF63_DC4C_8601_EC8C)
        #expect(PlaceholderColorPick.fnv1a("foobar") == 0x8594_4171_F739_67E8)
    }

    @Test("a title keeps its color, from launch to launch")
    func pinnedColors() {
        #expect(PlaceholderColorPick.color(forTitle: "Crepes") == .plum)
        #expect(PlaceholderColorPick.color(forTitle: "Bouillabaisse") == .teal)
        #expect(PlaceholderColorPick.color(forTitle: "Vinaigrette") == .tomato)
    }

    @Test("titles differing only in case, accents, or spacing share a color")
    func normalizedTitles() {
        let color = PlaceholderColorPick.color(forTitle: "Moules Marinieres")

        #expect(PlaceholderColorPick.color(forTitle: "moules  MARINIÈRES") == color)
        #expect(PlaceholderColorPick.color(forTitle: " Moules\tMarinieres ") == color)
    }

    @Test("the palette's colors are spread over titles")
    func spread() {
        let titles = [
            "Boeuf Bourguignon", "Bouillabaisse", "Brioche", "Crepes", "Croque Monsieur", "Gratin Dauphinois",
            "Madeleines", "Moules Marinieres", "Quiche Lorraine", "Vinaigrette"
        ]

        #expect(Set(titles.map(PlaceholderColorPick.color(forTitle:))).count > 5)
    }
}
