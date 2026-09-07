@testable import DesignSystem
import SwiftUI
import Testing

@Suite("Semantic color")
struct SousColorTests {
    /// Every ratio the two brand documents give.
    private static let documentedRatios: [StatedRatio] = [
        StatedRatio(
            foreground: SousPalette.ink,
            ground: SousPalette.paper,
            expected: 17.7
        ),
        StatedRatio(
            foreground: SousPalette.steel,
            ground: SousPalette.paper,
            expected: 4.9
        ),
        StatedRatio(
            foreground: SousPalette.ember,
            ground: SousPalette.paper,
            expected: 5.3
        ),
        StatedRatio(
            foreground: SousPalette.ink,
            ground: SousPalette.flame,
            expected: 5.5
        ),
        StatedRatio(
            foreground: SousPalette.paper,
            ground: SousPalette.char,
            expected: 17.0
        ),
        StatedRatio(
            foreground: SousPalette.chalk,
            ground: SousPalette.char,
            expected: 11.1
        ),
        StatedRatio(
            foreground: SousPalette.ash,
            ground: SousPalette.char,
            expected: 7.6
        ),
        StatedRatio(
            foreground: SousPalette.smoke,
            ground: SousPalette.char,
            expected: 5.5
        ),
        StatedRatio(
            foreground: SousPalette.flame,
            ground: SousPalette.char,
            expected: 5.3
        ),
        StatedRatio(
            foreground: SousPalette.paper,
            ground: SousPalette.pan,
            expected: 15.8
        ),
        StatedRatio(
            foreground: SousPalette.paper,
            ground: SousPalette.ember,
            expected: 5.3
        ),
        StatedRatio(
            foreground: SousPalette.flame,
            ground: SousPalette.pan,
            expected: 4.9
        ),
        StatedRatio(
            foreground: SousPalette.seam,
            ground: SousPalette.char,
            expected: 1.4
        ),
        StatedRatio(
            foreground: SousPalette.ember,
            ground: SousPalette.char,
            expected: 3.2
        )
    ]

    /// A contrast ratio one of the brand documents gives, with the pairing it applies to.
    private struct StatedRatio {
        let foreground: Color
        let ground: Color
        let expected: Double
    }

    @Test("on a light scheme the tokens draw the documented palette values")
    func lightTokens() {
        #expect(draws(SousColor.background, SousPalette.paper, in: .light))
        #expect(draws(SousColor.surface, SousPalette.white, in: .light))
        #expect(draws(SousColor.border, SousPalette.line, in: .light))
        #expect(draws(SousColor.text, SousPalette.ink, in: .light))
        #expect(draws(SousColor.textMuted, SousPalette.steel, in: .light))
        #expect(draws(SousColor.accent, SousPalette.flame, in: .light))
        #expect(draws(SousColor.accentText, SousPalette.ember, in: .light))
    }

    @Test("on a dark scheme the tokens draw the documented palette values")
    func darkTokens() {
        #expect(draws(SousColor.background, SousPalette.char, in: .dark))
        #expect(draws(SousColor.surface, SousPalette.pan, in: .dark))
        #expect(draws(SousColor.border, SousPalette.seam, in: .dark))
        #expect(draws(SousColor.text, SousPalette.paper, in: .dark))
        #expect(draws(SousColor.textMuted, SousPalette.ash, in: .dark))
        #expect(draws(SousColor.accent, SousPalette.flame, in: .dark))
        #expect(draws(SousColor.accentText, SousPalette.flame, in: .dark))
    }

    @Test("the palette matches the ratios both brand documents state")
    func statedRatios() {
        for entry in Self.documentedRatios {
            let ratio = contrastRatio(entry.foreground, entry.ground, in: .light)
            #expect(
                abs(ratio - entry.expected) < 0.12,
                "expected \(entry.expected), computed \(ratio)"
            )
        }
    }

    @Test("text passes AA against its own ground in both schemes")
    func textOnBackground() {
        for scheme in [ColorScheme.light, .dark] {
            let ratio = contrastRatio(SousColor.text, SousColor.background, in: scheme)
            #expect(ratio > 4.5, "text on background is \(ratio) in \(scheme)")
        }
    }

    @Test("muted text passes AA against both ground and surface in both schemes")
    func mutedText() {
        for scheme in [ColorScheme.light, .dark] {
            for ground in [SousColor.background, SousColor.surface] {
                let ratio = contrastRatio(SousColor.textMuted, ground, in: scheme)
                #expect(ratio > 4.5, "muted text is \(ratio) in \(scheme)")
            }
        }
    }

    @Test("accent text passes AA against the ground in both schemes")
    func accentText() {
        for scheme in [ColorScheme.light, .dark] {
            let ratio = contrastRatio(SousColor.accentText, SousColor.background, in: scheme)
            #expect(ratio > 4.5, "accent text on background is \(ratio) in \(scheme)")
        }
    }

    @Test("the accent surface carries Ink, not White")
    func accentCarriesInk() {
        #expect(contrastRatio(SousPalette.ink, SousPalette.flame, in: .light) > 4.5)
        #expect(contrastRatio(SousPalette.white, SousPalette.flame, in: .light) < 4.5)
    }

    /// Whether a token draws a palette value in a given scheme, to within one 8-bit step.
    ///
    /// A token reaches the screen through `UIColor`, which costs it a fraction of a step against
    /// the palette value it is built from.
    private func draws(_ token: Color, _ value: Color, in scheme: ColorScheme) -> Bool {
        let drawn = resolved(token, in: scheme)
        let stated = resolved(value, in: scheme)
        let step = Float(1.0 / 255.0)
        return abs(drawn.red - stated.red) < step
            && abs(drawn.green - stated.green) < step
            && abs(drawn.blue - stated.blue) < step
            && abs(drawn.opacity - stated.opacity) < step
    }

    /// The WCAG 2.1 contrast ratio between two colors, as each is drawn in a given scheme.
    private func contrastRatio(_ lhs: Color, _ rhs: Color, in scheme: ColorScheme) -> Double {
        let lighter = max(relativeLuminance(lhs, in: scheme), relativeLuminance(rhs, in: scheme))
        let darker = min(relativeLuminance(lhs, in: scheme), relativeLuminance(rhs, in: scheme))
        return (lighter + 0.05) / (darker + 0.05)
    }

    /// The WCAG 2.1 relative luminance of a color, as it is drawn in a given scheme.
    private func relativeLuminance(_ color: Color, in scheme: ColorScheme) -> Double {
        let resolved = resolved(color, in: scheme)
        return 0.2126 * linear(resolved.red)
            + 0.7152 * linear(resolved.green)
            + 0.0722 * linear(resolved.blue)
    }

    /// A color as it lands on screen in a given scheme.
    private func resolved(_ color: Color, in scheme: ColorScheme) -> Color.Resolved {
        var environment = EnvironmentValues()
        environment.colorScheme = scheme
        return color.resolve(in: environment)
    }

    /// One gamma-encoded channel, linearized.
    private func linear(_ channel: Float) -> Double {
        let value = Double(channel)
        return value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
    }
}
