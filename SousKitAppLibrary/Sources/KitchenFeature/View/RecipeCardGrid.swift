import SwiftUI

/// Cards in as many columns as fit, where the cards sharing a row are as tall as the tallest of them.
///
/// A card is offered its row's height, so it fills it with `.frame(maxHeight: .infinity)`.
struct RecipeCardGrid: Layout {
    /// The narrowest a column may be before the grid takes one column fewer.
    let minimumColumnWidth: CGFloat

    /// The space between two columns and between two rows.
    let spacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache _: inout Void
    ) -> CGSize {
        let width = proposal.width ?? minimumColumnWidth
        let rowHeights = rowHeights(of: subviews, width: width)
        let gaps = spacing * CGFloat(max(rowHeights.count - 1, 0))

        return CGSize(width: width, height: rowHeights.reduce(0.0, +) + gaps)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal _: ProposedViewSize,
        subviews: Subviews,
        cache _: inout Void
    ) {
        let columns = columnCount(in: bounds.width)
        let width = columnWidth(in: bounds.width)
        var top = bounds.minY

        for (row, height) in rowHeights(of: subviews, width: bounds.width).enumerated() {
            for column in 0..<columns where row * columns + column < subviews.count {
                subviews[row * columns + column].place(
                    at: CGPoint(x: bounds.minX + CGFloat(column) * (width + spacing), y: top),
                    proposal: ProposedViewSize(width: width, height: height)
                )
            }

            top += height + spacing
        }
    }

    private func columnCount(in width: CGFloat) -> Int {
        max(Int((width + spacing) / (minimumColumnWidth + spacing)), 1)
    }

    private func columnWidth(in width: CGFloat) -> CGFloat {
        let columns = CGFloat(columnCount(in: width))

        return max((width - spacing * (columns - 1.0)) / columns, 0.0)
    }

    /// The height of each row: that of its tallest card at the column's width.
    private func rowHeights(of subviews: Subviews, width: CGFloat) -> [CGFloat] {
        let columns = columnCount(in: width)
        let proposal = ProposedViewSize(width: columnWidth(in: width), height: nil)

        return stride(from: 0, to: subviews.count, by: columns).map { start in
            subviews[start..<min(start + columns, subviews.count)]
                .map({ $0.sizeThatFits(proposal).height })
                .max() ?? 0.0
        }
    }
}
