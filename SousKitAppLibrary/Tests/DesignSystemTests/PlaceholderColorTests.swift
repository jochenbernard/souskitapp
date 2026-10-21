import DesignSystem
import SwiftUI
import Testing

@Suite("Placeholder colors")
struct PlaceholderColorTests {
    private static let hexes: [SousPlaceholderColor: UInt32] = [
        .pink: 0xC17276,
        .orange: 0xB77E48,
        .yellow: 0x939043,
        .green: 0x599E6E,
        .teal: 0x279EA1,
        .blue: 0x5193C4,
        .indigo: 0x8982C6,
        .purple: 0xB075A7
    ]

    @Test("each color's OKLCH value lands on its sRGB hex", arguments: SousPlaceholderColor.allCases)
    func hex(of placeholderColor: SousPlaceholderColor) throws {
        let hex = try #require(Self.hexes[placeholderColor])
        let resolved = placeholderColor.color.resolve(in: EnvironmentValues())

        #expect(channel(resolved.red) == (hex >> 16) & 0xFF)
        #expect(channel(resolved.green) == (hex >> 8) & 0xFF)
        #expect(channel(resolved.blue) == hex & 0xFF)
    }

    @Test("each color lies inside sRGB", arguments: SousPlaceholderColor.allCases)
    func insideSRGB(_ placeholderColor: SousPlaceholderColor) {
        let resolved = placeholderColor.color.resolve(in: EnvironmentValues())

        #expect([resolved.linearRed, resolved.linearGreen, resolved.linearBlue].allSatisfy((0.0...1.0).contains))
    }

    @Test("the colors look the same in light and dark", arguments: SousPlaceholderColor.allCases)
    func sameInDark(_ placeholderColor: SousPlaceholderColor) {
        var dark = EnvironmentValues()
        dark.colorScheme = .dark

        #expect(placeholderColor.color.resolve(in: dark) == placeholderColor.color.resolve(in: EnvironmentValues()))
    }

    private func channel(_ component: Float) -> UInt32 {
        UInt32((Double(component) * 255.0).rounded())
    }
}
