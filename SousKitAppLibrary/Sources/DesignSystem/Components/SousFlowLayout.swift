import SwiftUI

/// Lays views out in rows, starting a new row where the next view does not fit.
public struct SousFlowLayout: Layout {
    private let spacing: CGFloat

    /// Creates a flow layout.
    ///
    /// - Parameter spacing: The gap between two views in a row, and between two rows.
    public init(spacing: CGFloat) {
        self.spacing = spacing
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache _: inout ()
    ) -> CGSize {
        let frames = frames(of: subviews, width: proposal.width ?? .infinity)

        return CGSize(
            width: frames.map(\.maxX).max() ?? 0.0,
            height: frames.map(\.maxY).max() ?? 0.0
        )
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal _: ProposedViewSize,
        subviews: Subviews,
        cache _: inout ()
    ) {
        let frames = frames(of: subviews, width: bounds.width)

        for (subview, frame) in zip(subviews, frames) {
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func frames(of subviews: Subviews, width: CGFloat) -> [CGRect] {
        var frames: [CGRect] = []
        var origin = CGPoint.zero
        var rowHeight = 0.0

        for subview in subviews {
            let size = size(of: subview, width: width)

            if origin.x > 0.0, origin.x + size.width > width {
                origin = CGPoint(x: 0.0, y: origin.y + rowHeight + spacing)
                rowHeight = 0.0
            }

            frames.append(CGRect(origin: origin, size: size))
            origin.x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return frames
    }

    private func size(of subview: LayoutSubview, width: CGFloat) -> CGSize {
        let size = subview.sizeThatFits(.unspecified)

        guard size.width > width else {
            return size
        }

        return subview.sizeThatFits(ProposedViewSize(width: width, height: nil))
    }
}
