import Foundation
@testable import KitchenFeature
import LocalizationTestSupport
import Testing

@Suite("Dutch strings")
struct DutchStringsTests {
    @Test("every English string has a Dutch one")
    func dutchCoversEnglish() throws {
        #expect(
            try LocalizableStrings.strings(of: "nl-BE", in: .module).keys
                == LocalizableStrings.strings(of: "en", in: .module).keys
        )
    }

    @Test("no Dutch string is left empty")
    func dutchIsWritten() throws {
        #expect(try LocalizableStrings.strings(of: "nl-BE", in: .module).values.allSatisfy({ !$0.isEmpty }))
    }

    @Test("the recipe count reads in Dutch, one recipe apart from many")
    func dutchRecipeCount() throws {
        let url = try #require(
            Bundle.module.url(
                forResource: "Localizable",
                withExtension: "stringsdict",
                subdirectory: nil,
                localization: "nl-BE"
            )
        )
        let strings = try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil)
        let plurals = try #require((strings as? [String: Any])?["%lld recipes"] as? [String: Any])
        let variations = try #require(plurals.values.compactMap({ $0 as? [String: String] }).first)

        #expect(variations["one"] == "%lld recept")
        #expect(variations["other"] == "%lld recepten")
    }
}
