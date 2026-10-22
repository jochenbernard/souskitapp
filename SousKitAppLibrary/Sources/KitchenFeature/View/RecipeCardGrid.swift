import DesignSystem
import SwiftUI

/// Cards in as many columns as fit, where the cards sharing a row are as tall as the tallest of them, built as they
/// scroll into view.
///
/// A card is offered its row's height, so it fills it with `.frame(maxHeight: .infinity)`.
struct RecipeCardGrid<Content: View>: View {
    private let minimumColumnWidth: CGFloat
    private let spacing: CGFloat
    private let content: Content

    /// Creates a grid.
    ///
    /// - Parameters:
    ///   - minimumColumnWidth: The narrowest a column may be before the grid takes one column fewer.
    ///   - spacing: The space between two columns and between two rows.
    ///   - content: The cards.
    init(
        minimumColumnWidth: CGFloat,
        spacing: CGFloat,
        @ViewBuilder content: () -> Content
    ) {
        self.minimumColumnWidth = minimumColumnWidth
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: minimumColumnWidth), spacing: spacing)],
            spacing: spacing
        ) {
            content
        }
    }
}

#Preview {
    ScrollView {
        RecipeCardGrid(minimumColumnWidth: 160.0, spacing: SousSpacing.medium) {
            ForEach([80.0, 120.0, 60.0, 100.0, 140.0], id: \.self) { height in
                Color.accentColor
                    .frame(minHeight: height)
                    .frame(maxHeight: .infinity)
            }
        }
        .sousPagePadding()
    }
    .sousPage()
}
