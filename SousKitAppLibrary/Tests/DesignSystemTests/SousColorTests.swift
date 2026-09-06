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

    @Test("light tokens map to the documented palette values")
    func lightTokens() {
        #expect(SousColor.background.color(in: .light) == SousPalette.paper)
        #expect(SousColor.surface.color(in: .light) == SousPalette.white)
        #expect(SousColor.border.color(in: .light) == SousPalette.line)
        #expect(SousColor.text.color(in: .light) == SousPalette.ink)
        #expect(SousColor.textMuted.color(in: .light) == SousPalette.steel)
        #expect(SousColor.accent.color(in: .light) == SousPalette.flame)
        #expect(SousColor.accentText.color(in: .light) == SousPalette.ember)
    }

    @Test("dark tokens map to the documented palette values")
    func darkTokens() {
        #expect(SousColor.background.color(in: .dark) == SousPalette.char)
        #expect(SousColor.surface.color(in: .dark) == SousPalette.pan)
        #expect(SousColor.border.color(in: .dark) == SousPalette.seam)
        #expect(SousColor.text.color(in: .dark) == SousPalette.paper)
        #expect(SousColor.textMuted.color(in: .dark) == SousPalette.ash)
        #expect(SousColor.accent.color(in: .dark) == SousPalette.flame)
        #expect(SousColor.accentText.color(in: .dark) == SousPalette.flame)
    }

    @Test("the palette matches the ratios both brand documents state")
    func statedRatios() {
        for entry in Self.documentedRatios {
            let ratio = contrastRatio(entry.foreground, entry.ground)
            #expect(
                abs(ratio - entry.expected) < 0.12,
                "expected \(entry.expected), computed \(ratio)"
            )
        }
    }

    @Test("text passes AA against its own ground in both schemes")
    func textOnBackground() {
        for scheme in [ColorScheme.light, .dark] {
            let ratio = contrastRatio(
                SousColor.text.color(in: scheme),
                SousColor.background.color(in: scheme)
            )
            #expect(ratio > 4.5, "text on background is \(ratio) in \(scheme)")
        }
    }

    @Test("muted text passes AA against both ground and surface in both schemes")
    func mutedText() {
        for scheme in [ColorScheme.light, .dark] {
            for ground in [SousColor.background, .surface] {
                let ratio = contrastRatio(
                    SousColor.textMuted.color(in: scheme),
                    ground.color(in: scheme)
                )
                #expect(ratio > 4.5, "muted text is \(ratio) in \(scheme)")
            }
        }
    }

    @Test("accent text passes AA against the ground in both schemes")
    func accentText() {
        for scheme in [ColorScheme.light, .dark] {
            let ratio = contrastRatio(
                SousColor.accentText.color(in: scheme),
                SousColor.background.color(in: scheme)
            )
            #expect(ratio > 4.5, "accent text on background is \(ratio) in \(scheme)")
        }
    }

    @Test("the accent surface carries Ink, not White")
    func accentCarriesInk() {
        #expect(contrastRatio(SousPalette.ink, SousPalette.flame) > 4.5)
        #expect(contrastRatio(SousPalette.white, SousPalette.flame) < 4.5)
    }

    /// The WCAG 2.1 contrast ratio between two colors.
    private func contrastRatio(_ lhs: Color, _ rhs: Color) -> Double {
        let lighter = max(relativeLuminance(lhs), relativeLuminance(rhs))
        let darker = min(relativeLuminance(lhs), relativeLuminance(rhs))
        return (lighter + 0.05) / (darker + 0.05)
    }

    /// The WCAG 2.1 relative luminance of a color.
    private func relativeLuminance(_ color: Color) -> Double {
        let resolved = color.resolve(in: EnvironmentValues())
        return 0.2126 * linear(resolved.red)
            + 0.7152 * linear(resolved.green)
            + 0.0722 * linear(resolved.blue)
    }

    /// One gamma-encoded channel, linearized.
    private func linear(_ channel: Float) -> Double {
        let value = Double(channel)
        return value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
    }
}
