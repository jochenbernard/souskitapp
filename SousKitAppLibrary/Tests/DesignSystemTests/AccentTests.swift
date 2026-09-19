import DesignSystem
import SwiftUI
import Testing

@Suite("Accent")
struct AccentTests {
    /// The `AccentColor` color set in the app's asset catalog, the subset of it read here.
    private struct ColorSet: Decodable {
        struct Entry: Decodable {
            let color: Value
        }

        struct Value: Decodable {
            let components: Components
        }

        struct Components: Decodable {
            let red: String
            let green: String
            let blue: String
        }

        let colors: [Entry]
    }

    @Test("the accent matches the app's asset catalog")
    func accentMatchesAssetCatalog() throws {
        let url = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .appending(path: "../../../SousKitApp/Assets/Assets.xcassets/AccentColor.colorset/Contents.json")
        let colorSet = try JSONDecoder().decode(ColorSet.self, from: Data(contentsOf: url))
        let components = try #require(colorSet.colors.first).color.components
        let accent = resolved(.accent)

        #expect(try abs(Double(accent.red) - channel(components.red)) < 0.5 / 255.0)
        #expect(try abs(Double(accent.green) - channel(components.green)) < 0.5 / 255.0)
        #expect(try abs(Double(accent.blue) - channel(components.blue)) < 0.5 / 255.0)
    }

    @Test("white text on the accent passes AA")
    func accentCarriesWhite() {
        #expect(contrastRatio(.white, .accent) >= 4.5)
    }

    /// One channel of an asset catalog color, in whichever of Xcode's three input methods it was saved.
    private func channel(_ component: String) throws -> Double {
        if component.hasPrefix("0x") {
            return Double(try #require(UInt8(component.dropFirst(2), radix: 16))) / 255.0
        }

        if component.contains(".") {
            return try #require(Double(component))
        }

        return Double(try #require(UInt8(component))) / 255.0
    }

    /// The WCAG 2.1 contrast ratio between two colors.
    private func contrastRatio(_ lhs: Color, _ rhs: Color) -> Double {
        let lighter = max(relativeLuminance(lhs), relativeLuminance(rhs))
        let darker = min(relativeLuminance(lhs), relativeLuminance(rhs))
        return (lighter + 0.05) / (darker + 0.05)
    }

    /// The WCAG 2.1 relative luminance of a color.
    private func relativeLuminance(_ color: Color) -> Double {
        let resolved = resolved(color)
        return 0.2126 * linear(resolved.red)
            + 0.7152 * linear(resolved.green)
            + 0.0722 * linear(resolved.blue)
    }

    /// A color as it lands on screen.
    private func resolved(_ color: Color) -> Color.Resolved {
        color.resolve(in: EnvironmentValues())
    }

    /// One gamma-encoded channel, linearized.
    private func linear(_ channel: Float) -> Double {
        let value = Double(channel)
        return value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
    }
}
