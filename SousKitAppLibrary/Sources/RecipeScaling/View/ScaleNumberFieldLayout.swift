import SwiftUI

/// The minus, the field and the plus on one line where the number shows whole there, and otherwise the field on a
/// line of its own with the minus and the plus under it.
///
/// It takes the minus, the field, the plus and the number set in the field's font, in that order. One layout places
/// both arrangements, so the field is the same view in either and keeps the keyboard when the number outgrows the row.
struct ScaleNumberFieldLayout: Layout {
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

        return arrangement(of: subviews, proposal: proposal).size
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

        for (subview, frame) in zip(subviews, arrangement(of: subviews, proposal: proposal).frames) {
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
        subviews[3].place(at: bounds.origin, proposal: .unspecified)
    }

    // The frames of the minus, the field and the plus, and the size they take up together.
    private func arrangement(of subviews: Subviews, proposal: ProposedViewSize) -> (size: CGSize, frames: [CGRect]) {
        let row = row(of: subviews, proposal: proposal)
        let rowWidth = row.map(\.width).reduce(spacing * 2.0, +)
        let number = subviews[3].sizeThatFits(.unspecified).width

        if let width = proposal.width, rowWidth > width + Self.tolerance || number > row[1].width {
            return stack(of: subviews, width: width)
        }

        let rowHeight = row.map(\.height).max() ?? 0.0
        var minX = 0.0
        var frames: [CGRect] = []

        for size in row {
            frames.append(CGRect(origin: CGPoint(x: minX, y: (rowHeight - size.height) / 2.0), size: size))
            minX += size.width + spacing
        }

        return (size: CGSize(width: rowWidth, height: rowHeight), frames: frames)
    }

    // The minus and the plus are served ahead of the field, and the field gets no more than its ideal width.
    private func row(of subviews: Subviews, proposal: ProposedViewSize) -> [CGSize] {
        let height = proposal.height

        guard let width = proposal.width else {
            return subviews[0 ..< 3].map({ $0.sizeThatFits(ProposedViewSize(width: nil, height: height)) })
        }

        let fieldMinimum = subviews[1].sizeThatFits(ProposedViewSize(width: 0.0, height: height)).width
        let fieldIdeal = subviews[1].sizeThatFits(ProposedViewSize(width: nil, height: height)).width
        let available = width - spacing * 2.0
        let steps = max(available - fieldMinimum, 0.0)
        let minus = subviews[0].sizeThatFits(ProposedViewSize(width: steps / 2.0, height: height))
        let plus = subviews[2].sizeThatFits(ProposedViewSize(width: max(steps - minus.width, 0.0), height: height))
        let fieldWidth = min(max(available - minus.width - plus.width, 0.0), fieldIdeal)
        let field = subviews[1].sizeThatFits(ProposedViewSize(width: fieldWidth, height: height))

        return [minus, field, plus]
    }

    private func stack(of subviews: Subviews, width: CGFloat) -> (size: CGSize, frames: [CGRect]) {
        let stepWidth = max(width - spacing, 0.0) / 2.0
        let minus = subviews[0].sizeThatFits(ProposedViewSize(width: stepWidth, height: nil))
        let field = subviews[1].sizeThatFits(ProposedViewSize(width: width, height: nil))
        let plus = subviews[2].sizeThatFits(ProposedViewSize(width: stepWidth, height: nil))

        let stepsY = field.height + spacing
        let stepsHeight = max(minus.height, plus.height)
        let minusX = (field.width - minus.width - spacing - plus.width) / 2.0
        let plusX = minusX + minus.width + spacing

        return (
            size: CGSize(width: field.width, height: stepsY + stepsHeight),
            frames: [
                CGRect(origin: CGPoint(x: minusX, y: stepsY + (stepsHeight - minus.height) / 2.0), size: minus),
                CGRect(origin: .zero, size: field),
                CGRect(origin: CGPoint(x: plusX, y: stepsY + (stepsHeight - plus.height) / 2.0), size: plus)
            ]
        )
    }
}
