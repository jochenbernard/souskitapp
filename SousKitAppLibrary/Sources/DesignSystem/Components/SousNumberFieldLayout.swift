import SwiftUI

/// The minus, the field and the plus on one line where the number shows whole there, and otherwise the field on a
/// line of its own with the minus and the plus under it.
///
/// It takes the minus, the field, the plus and the number set in the field's font, in that order. One layout places
/// both arrangements, so the field is the same view in either and keeps the keyboard when the number outgrows the row.
struct SousNumberFieldLayout: Layout {
    private enum Arrangement {
        /// The row, laid out by an `HStack` given this proposal.
        case row(ProposedViewSize)

        /// The field above the minus and the plus, this wide.
        case stack(CGFloat)
    }

    // A row that fills the width can come out a rounding error wider than it.
    private static let tolerance = 0.5

    let spacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache _: inout ()
    ) -> CGSize {
        guard subviews.count == 4 else {
            return .zero
        }

        switch arrangement(of: subviews, proposal: proposal) {
        case .row(let rowProposal):
            return size(
                of: HStackLayout(spacing: spacing),
                proposal: rowProposal,
                subviews: subviews[0 ..< 3]
            )

        case .stack(let width):
            return stack(of: subviews, width: width).size
        }
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache _: inout ()
    ) {
        guard subviews.count == 4 else {
            return
        }

        switch arrangement(of: subviews, proposal: proposal) {
        case .row(let rowProposal):
            place(
                HStackLayout(spacing: spacing),
                in: bounds,
                proposal: rowProposal,
                subviews: subviews[0 ..< 3]
            )
            subviews[3].place(at: bounds.origin, proposal: .unspecified)

        case .stack(let width):
            for (subview, frame) in zip(subviews, stack(of: subviews, width: width).frames) {
                subview.place(
                    at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                    proposal: ProposedViewSize(frame.size)
                )
            }
        }
    }

    // Measures the row as an `HStack` lays it out, the minus and the plus served ahead of the field.
    private func arrangement(of subviews: Subviews, proposal: ProposedViewSize) -> Arrangement {
        guard let width = proposal.width else {
            return .row(proposal)
        }

        let height = proposal.height
        let fieldMinimum = subviews[1].sizeThatFits(ProposedViewSize(width: 0.0, height: height)).width
        let fieldIdeal = subviews[1].sizeThatFits(ProposedViewSize(width: nil, height: height)).width
        let available = width - spacing * 2.0
        let steps = max(available - fieldMinimum, 0.0)
        let minus = subviews[0].sizeThatFits(ProposedViewSize(width: steps / 2.0, height: height)).width
        let plus = subviews[2].sizeThatFits(ProposedViewSize(width: max(steps - minus, 0.0), height: height)).width
        let fieldProposal = ProposedViewSize(width: min(max(available - minus - plus, 0.0), fieldIdeal), height: height)
        let field = subviews[1].sizeThatFits(fieldProposal).width
        let rowWidth = minus + field + plus + spacing * 2.0
        let number = subviews[3].sizeThatFits(.unspecified).width

        guard rowWidth <= width + Self.tolerance, number <= field else {
            return .stack(width)
        }

        // Only as wide as the row comes to, so the field gets no more than its ideal width.
        return .row(ProposedViewSize(width: rowWidth, height: height))
    }

    // `HStackLayout` answers only through `Layout`, so a generic function reaches it.
    private func size(
        of layout: some Layout,
        proposal: ProposedViewSize,
        subviews: Subviews
    ) -> CGSize {
        var cache = layout.makeCache(subviews: subviews)

        return layout.sizeThatFits(
            proposal: proposal,
            subviews: subviews,
            cache: &cache
        )
    }

    private func place(
        _ layout: some Layout,
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews
    ) {
        var cache = layout.makeCache(subviews: subviews)
        layout.placeSubviews(
            in: bounds,
            proposal: proposal,
            subviews: subviews,
            cache: &cache
        )
    }

    private func stack(of subviews: Subviews, width: CGFloat) -> (size: CGSize, frames: [CGRect]) {
        let stepWidth = max(width - spacing, 0.0) / 2.0
        let minus = subviews[0].sizeThatFits(ProposedViewSize(width: stepWidth, height: nil))
        let field = subviews[1].sizeThatFits(ProposedViewSize(width: width, height: nil))
        let plus = subviews[2].sizeThatFits(ProposedViewSize(width: stepWidth, height: nil))
        let number = subviews[3].sizeThatFits(.unspecified)

        let stepsY = field.height + spacing
        let stepsHeight = max(minus.height, plus.height)
        let minusX = (field.width - minus.width - spacing - plus.width) / 2.0
        let plusX = minusX + minus.width + spacing

        return (
            size: CGSize(width: field.width, height: stepsY + stepsHeight),
            frames: [
                CGRect(origin: CGPoint(x: minusX, y: stepsY + (stepsHeight - minus.height) / 2.0), size: minus),
                CGRect(origin: .zero, size: field),
                CGRect(origin: CGPoint(x: plusX, y: stepsY + (stepsHeight - plus.height) / 2.0), size: plus),
                CGRect(origin: .zero, size: number)
            ]
        )
    }
}
