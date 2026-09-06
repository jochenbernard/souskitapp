import SwiftUI

/// Applies a ``SousTextStyle``, scaled for Dynamic Type and optionally corrected to its line
/// height.
///
/// The correction needs both `lineSpacing` and padding: `lineSpacing` clamps at zero, so an
/// entry set tighter than its face reaches its line box through negative padding alone.
private struct SousTextStyleModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    @ScaledMetric private var scaledSize: CGFloat

    private let style: SousTextStyle
    private let correctsLineBox: Bool

    init(style: SousTextStyle, correctsLineBox: Bool) {
        self.style = style
        self.correctsLineBox = correctsLineBox
        self._scaledSize = ScaledMetric(wrappedValue: style.size, relativeTo: style.textStyle)
    }

    func body(content: Content) -> some View {
        let face = style.face(in: colorScheme)
        let ratio = scaledSize / style.size
        let leading = (style.lineHeight * ratio) - face.naturalLineHeight(size: scaledSize)

        content
            .font(face.font(size: scaledSize))
            .tracking(style.tracking * ratio)
            .lineSpacing(max(0.0, leading))
            .padding(.vertical, correctsLineBox ? leading / 2.0 : 0.0)
    }
}

extension Text {
    /// Sets this text in an entry of the Sous type scale, occupying that entry's line height.
    ///
    /// - Parameter style: The entry to apply.
    /// - Returns: The text, set in that entry.
    @MainActor
    public func sousTextStyle(_ style: SousTextStyle) -> some View {
        modifier(SousTextStyleModifier(style: style, correctsLineBox: true))
    }
}

extension View {
    /// Sets the face, size, and tracking of a type scale entry on every text this view holds.
    ///
    /// For text a `Text` does not carry: a `TextField`, a `Label`, a stack of several. The line
    /// box is left alone; ``SwiftUI/Text/sousTextStyle(_:)`` is the one that lands on it.
    ///
    /// - Parameter style: The entry to apply.
    /// - Returns: The view, set in that entry.
    public func sousFont(_ style: SousTextStyle) -> some View {
        modifier(SousTextStyleModifier(style: style, correctsLineBox: false))
    }

    /// Sets a type scale entry on a view holding exactly one text block, line box included.
    ///
    /// A view holding several texts loses one correction per extra text.
    ///
    /// - Parameter style: The entry to apply.
    /// - Returns: The view, set in that entry.
    func sousTextBlock(_ style: SousTextStyle) -> some View {
        modifier(SousTextStyleModifier(style: style, correctsLineBox: true))
    }
}

#Preview("Type scale") {
    VStack(alignment: .leading, spacing: SousSpacing.medium) {
        Text("Madeleines")
            .sousTextStyle(.display)

        Text("Boeuf Bourguignon")
            .sousTextStyle(.title)

        Text("Cover the pot and braise at 150C for 3 h, until the beef gives to a fork.")
            .sousTextStyle(.heading)

        Text(
            """
            Peel 1.2 kg potatoes and slice them 3 mm thick on a mandoline, then bring them \
            to a simmer in 500 ml cream and 300 ml milk in a heavy pot with salt, black \
            pepper, and 1/4 tsp nutmeg.
            """
        )
        .sousTextStyle(.body)

        Text(verbatim: "1.2 kg \u{B7} 150C \u{B7} 3 h \u{B7} serves 6")
            .sousTextStyle(.data)

        Text(verbatim: "dinner \u{B7} classic \u{B7} french")
            .sousTextStyle(.eyebrow)
    }
    .foregroundStyle(SousColor.text)
    .padding(SousSpacing.xLarge)
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .topLeading
    )
    .background(SousColor.background)
}

#Preview("Line box, against sousFont") {
    HStack(alignment: .top, spacing: SousSpacing.xLarge) {
        VStack(spacing: 0.0) {
            Text(verbatim: "garlic")
                .sousTextStyle(.body)

            Text(verbatim: "garlic")
                .sousTextStyle(.body)

            Text(verbatim: "garlic")
                .sousTextStyle(.body)
        }
        .background(SousPalette.scorch)

        VStack(spacing: 0.0) {
            Text(verbatim: "garlic")

            Text(verbatim: "garlic")

            Text(verbatim: "garlic")
        }
        .sousFont(.body)
        .background(SousPalette.scorch)
    }
    .foregroundStyle(SousColor.text)
    .padding(SousSpacing.xLarge)
    .background(SousColor.background)
}
