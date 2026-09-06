@testable import DesignSystem
import SwiftUI
import Testing

@MainActor
@Suite("Type scale")
struct SousTextStyleTests {
    @Test(
        "one styled text occupies its line height",
        arguments: [SousTextStyle.display, .title, .heading, .body, .data, .eyebrow]
    )
    func oneTextOccupiesItsLineHeight(style: SousTextStyle) {
        let measured = Self.height(
            Text(verbatim: "Ag")
                .sousTextStyle(style)
        )
        #expect(
            abs(measured - style.lineHeight) <= 1.0,
            "measured \(measured), line height \(style.lineHeight)"
        )
    }

    @Test(
        "three styled texts stack to three line heights",
        arguments: [SousTextStyle.display, .title, .heading, .body, .data, .eyebrow]
    )
    func styledTextsStackToTheirLineHeights(style: SousTextStyle) {
        let measured = Self.height(
            VStack(spacing: 0.0) {
                Text(verbatim: "Ag")
                    .sousTextStyle(style)

                Text(verbatim: "Ag")
                    .sousTextStyle(style)

                Text(verbatim: "Ag")
                    .sousTextStyle(style)
            }
        )
        let expected = style.lineHeight * 3.0
        #expect(abs(measured - expected) <= 3.0, "measured \(measured), expected \(expected)")
    }

    @Test(
        "sousFont measures the same on a container as on each text",
        arguments: [SousTextStyle.display, .title, .heading, .body, .data, .eyebrow]
    )
    func sousFontIsContainerSafe(style: SousTextStyle) {
        let each = Self.height(
            VStack(spacing: 0.0) {
                Text(verbatim: "Ag")
                    .sousFont(style)

                Text(verbatim: "Ag")
                    .sousFont(style)

                Text(verbatim: "Ag")
                    .sousFont(style)
            }
        )
        let wrapped = Self.height(
            VStack(spacing: 0.0) {
                Text(verbatim: "Ag")

                Text(verbatim: "Ag")

                Text(verbatim: "Ag")
            }
            .sousFont(style)
        )
        #expect(each == wrapped, "each \(each), wrapped \(wrapped)")
    }

    /// The rendered height in points, rounded up to whole pixels by the renderer.
    private static func height(_ view: some View) -> CGFloat {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0
        return renderer.cgImage.map({ CGFloat($0.height) }) ?? -1.0
    }
}
