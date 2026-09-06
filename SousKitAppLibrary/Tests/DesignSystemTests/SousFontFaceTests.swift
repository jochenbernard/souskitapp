import CoreText
@testable import DesignSystem
import Foundation
import Testing

@Suite("Bundled fonts")
struct SousFontFaceTests {
    @Test("every face ships in the resource bundle", arguments: SousFontFace.allCases)
    func faceIsBundled(face: SousFontFace) {
        let url = Bundle.module.url(
            forResource: face.rawValue,
            withExtension: "ttf",
            subdirectory: "Fonts"
        )
        #expect(url != nil, "\(face.rawValue).ttf is missing from Resources/Fonts")
    }

    @Test("every face resolves under its own PostScript name", arguments: SousFontFace.allCases)
    func faceResolves(face: SousFontFace) {
        SousFontFace.registerBundledFonts()
        let font = CTFontCreateWithName(face.postScriptName as CFString, 17.0, nil)
        let resolved = CTFontCopyPostScriptName(font) as String
        #expect(
            resolved == face.postScriptName,
            "asked for \(face.postScriptName), Core Text substituted \(resolved)"
        )
    }

    @Test("a face reports a usable natural line height", arguments: SousFontFace.allCases)
    func faceHasMetrics(face: SousFontFace) {
        #expect(face.naturalLineHeight(size: 17.0) > 0.0)
    }
}
