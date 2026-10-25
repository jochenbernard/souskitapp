import DesignSystem
import SwiftUI

private struct CardPreviewModifier: ViewModifier {
    let size: CGSize

    func body(content: Content) -> some View {
        content
            // Narrower where the system narrows a preview taller than the room it has, keeping its proportions.
            .frame(idealWidth: size.width, maxWidth: size.width)
            // A context menu's preview of no fixed height never opens.
            .fixedSize(horizontal: false, vertical: true)
            // Taller than the room left, a preview is cut at its bottom rather than cropped around its middle.
            .frame(maxHeight: size.height, alignment: .top)
            .clipped()
    }
}

extension View {
    /// Sizes this view as a card's preview in a context menu.
    ///
    /// - Parameter size: The width the preview takes where it has the room, and the most height.
    /// - Returns: The view, sized as a preview.
    func cardPreview(fitting size: CGSize) -> some View {
        modifier(CardPreviewModifier(size: size))
    }
}

#Preview("Card preview") {
    VStack(alignment: .leading, spacing: SousSpacing.medium) {
        ForEach(1...12, id: \.self) { index in
            Text(verbatim: "Line \(index)")
        }
    }
    .padding(SousSpacing.large)
    .cardPreview(fitting: CGSize(width: 320.0, height: 200.0))
    .sousRowSurface()
}
