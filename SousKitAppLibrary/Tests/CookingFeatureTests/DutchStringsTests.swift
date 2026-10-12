@testable import CookingFeature
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

    @Test("a custom timer goes off under a title leading with its length, which the system would cut off the end")
    func customTimerTitleLeadsWithItsLength() throws {
        #expect(try LocalizableStrings.strings(of: "nl-BE", in: .module)["Custom %@ timer"]?.hasPrefix("%@") == true)
    }
}
