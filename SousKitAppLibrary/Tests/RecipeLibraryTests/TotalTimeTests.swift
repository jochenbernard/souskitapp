import RecipeLibrary
import SousKit
import Testing

@Suite("Total time")
struct TotalTimeTests {
    private let parser = SousParser()

    private func totalTime(of header: String) -> TotalTime? {
        TotalTime(metadata: parser.parseRecipe("---\n\(header)\n---").value.metadata, parser: parser)
    }

    @Test("a header's total time is read as it is written")
    func total() {
        #expect(totalTime(of: "total-time: 1 h 30 min") == .duration(.seconds(5_400.0)))
    }

    @Test("a total time stands over prep and cook")
    func totalOverParts() {
        #expect(totalTime(of: "prep-time: 30 min\ncook-time: 3 h\ntotal-time: 4 h") == .duration(.seconds(14_400.0)))
    }

    @Test("prep and cook are added up where the header gives no total")
    func prepAndCook() {
        #expect(totalTime(of: "prep-time: 30 min\ncook-time: 3 h") == .duration(.seconds(12_600.0)))
    }

    @Test("prep alone is the total where the header gives nothing else")
    func prepAlone() {
        #expect(totalTime(of: "prep-time: 5 min") == .duration(.seconds(300.0)))
    }

    @Test("Dutch units read as English ones do")
    func dutchUnits() {
        #expect(totalTime(of: "prep-time: 1 uur\ncook-time: 20 minuten") == .duration(.seconds(4_800.0)))
    }

    @Test("a total that names no length of time is kept as written")
    func writtenTotal() {
        #expect(totalTime(of: "total-time: overnight") == .written("overnight"))
    }

    @Test("prep and cook are not added up where one of them does not read")
    func unreadablePart() {
        #expect(totalTime(of: "prep-time: 30 min\ncook-time: until golden") == nil)
    }

    @Test("a time key written with no value gives no time")
    func emptyValue() {
        #expect(totalTime(of: "total-time:\nprep-time: 30 min\ncook-time: 3 h") == .duration(.seconds(12_600.0)))
        #expect(totalTime(of: "prep-time:\ncook-time: 3 h") == .duration(.seconds(10_800.0)))
        #expect(totalTime(of: "total-time:") == nil)
    }

    @Test("a header giving no time gives no total")
    func noTime() {
        #expect(totalTime(of: "title: Vinaigrette\nservings: 4") == nil)
        #expect(TotalTime(metadata: parser.parseRecipe("Whisk it.").value.metadata, parser: parser) == nil)
    }
}
