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

    @Test("white text on the accent reaches Lc 60")
    func accentCarriesWhite() {
        #expect(abs(lightnessContrast(text: .white, background: .accent)) >= 60.0)
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

    /// The APCA 0.0.98G lightness contrast of text on a background, negative for light text on dark.
    private func lightnessContrast(text: Color, background: Color) -> Double {
        let textLuminance = screenLuminance(text)
        let backgroundLuminance = screenLuminance(background)

        guard
            abs(backgroundLuminance - textLuminance) >= 0.0005
        else {
            return 0.0
        }

        if backgroundLuminance > textLuminance {
            let contrast = (pow(backgroundLuminance, 0.56) - pow(textLuminance, 0.57)) * 1.14
            return contrast < 0.1 ? 0.0 : (contrast - 0.027) * 100.0
        }

        let contrast = (pow(backgroundLuminance, 0.65) - pow(textLuminance, 0.62)) * 1.14
        return contrast > -0.1 ? 0.0 : (contrast + 0.027) * 100.0
    }

    /// The APCA screen luminance of a color, soft-clamped near black.
    private func screenLuminance(_ color: Color) -> Double {
        let resolved = resolved(color)
        let luminance = 0.2126729 * pow(Double(resolved.red), 2.4)
            + 0.7151522 * pow(Double(resolved.green), 2.4)
            + 0.0721750 * pow(Double(resolved.blue), 2.4)
        return luminance < 0.022 ? luminance + pow(0.022 - luminance, 1.414) : luminance
    }

    /// A color as it lands on screen.
    private func resolved(_ color: Color) -> Color.Resolved {
        color.resolve(in: EnvironmentValues())
    }
}
