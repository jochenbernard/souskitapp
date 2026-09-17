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
}
