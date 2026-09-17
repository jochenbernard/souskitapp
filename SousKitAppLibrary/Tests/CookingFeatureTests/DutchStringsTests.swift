@testable import CookingFeature
import Foundation
import Testing

@Suite("Dutch strings")
struct DutchStringsTests {
    @Test("every English string has a Dutch one")
    func dutchCoversEnglish() throws {
        #expect(try strings(of: "nl-BE").keys == strings(of: "en").keys)
    }

    @Test("no Dutch string is left empty")
    func dutchIsWritten() throws {
        #expect(try strings(of: "nl-BE").values.allSatisfy({ !$0.isEmpty }))
    }

    private func strings(of localization: String) throws -> [String: String] {
        let url = try #require(
            Bundle.module.url(
                forResource: "Localizable",
                withExtension: "strings",
                subdirectory: nil,
                localization: localization
            )
        )

        return try PropertyListDecoder().decode([String: String].self, from: Data(contentsOf: url))
    }
}
