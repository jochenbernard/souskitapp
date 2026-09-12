import SwiftUI

/// The five faces the type scale is set in, bundled under the SIL Open Font License.
///
/// They register with Core Text on first use, so an app needs no setup call. Each raw value
/// is the face's PostScript name.
public enum SousFontFace: String, CaseIterable, Sendable {
    /// Archivo 400, for body copy and method steps.
    case archivoRegular = "Archivo-Regular"

    /// Archivo 500, for headings and UI.
    case archivoMedium = "Archivo-Medium"

    /// Archivo 600, for the wordmark, lockups, and ``SousTextStyle/display``.
    case archivoSemiBold = "Archivo-SemiBold"

    /// JetBrains Mono 400, for code and monospace passages.
    case jetBrainsMonoRegular = "JetBrainsMono-Regular"

    /// JetBrains Mono 500, for quantities, metadata, and eyebrows.
    case jetBrainsMonoMedium = "JetBrainsMono-Medium"

    /// The name Core Text and `Font.custom` match this face on.
    public var postScriptName: String { rawValue }

    /// Registers the bundled faces with Core Text, once per process, from any thread.
    public static func registerBundledFonts() {
        _ = registrationHasRun
    }

    /// The face at a fixed point size, which Dynamic Type does not scale.
    ///
    /// ``SwiftUI/Text/sousTextStyle(_:)`` scales before calling this; a size passed here
    /// directly stays put.
    ///
    /// - Parameter size: The point size to set the face at.
    /// - Returns: A font for this face.
    public func font(size: CGFloat) -> Font {
        Self.registerBundledFonts()
        return .custom(postScriptName, fixedSize: size)
    }

    /// The face's ascent, descent, and leading at a size, summed.
    ///
    /// - Parameter size: The point size to measure at.
    /// - Returns: The line height in points.
    public func naturalLineHeight(size: CGFloat) -> CGFloat {
        Self.unitLineHeights[self, default: 0.0] * size
    }

    /// Every face's line height at one point, measured once.
    ///
    /// Core Text scales these metrics with the point size, so one measurement per face answers
    /// every size, and the type scale measures nothing again on a redraw.
    private static let unitLineHeights: [SousFontFace: CGFloat] = {
        registerBundledFonts()

        return Dictionary(
            uniqueKeysWithValues: allCases.map { face in
                let font = CTFontCreateWithName(face.postScriptName as CFString, 1.0, nil)
                let ascent = CTFontGetAscent(font)
                let descent = CTFontGetDescent(font)

                return (face, ascent + descent + CTFontGetLeading(font))
            }
        )
    }()

    /// Registration, run lazily on first access.
    ///
    /// The assertion is the only report of a missing face; `Font.custom` substitutes silently.
    private static let registrationHasRun: Void = {
        for face in SousFontFace.allCases {
            let url = Bundle.module.url(
                forResource: face.rawValue,
                withExtension: "ttf",
                subdirectory: "Fonts"
            )
            let registered = url.map { url in
                CTFontManagerRegisterFontsForURL(
                    url as CFURL,
                    .process,
                    nil
                )
            } ?? false
            assert(registered, "Sous: could not register bundled font \(face.rawValue).ttf")
        }
    }()
}
