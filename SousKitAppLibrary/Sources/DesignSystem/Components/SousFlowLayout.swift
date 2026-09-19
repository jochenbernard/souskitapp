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

    /// The size each view takes unconstrained, which a pass measures once however often it is asked for.
    public func makeCache(subviews: Subviews) -> [CGSize?] {
        Array(repeating: nil, count: subviews.count)
    }

    public func updateCache(_ cache: inout [CGSize?], subviews: Subviews) {
        cache = makeCache(subviews: subviews)
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout [CGSize?]
    ) -> CGSize {
        var size = CGSize.zero

        for frame in frames(of: subviews, width: proposal.width ?? .infinity, cache: &cache) {
            size.width = max(size.width, frame.maxX)
            size.height = max(size.height, frame.maxY)
        }

        return size
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal _: ProposedViewSize,
        subviews: Subviews,
        cache: inout [CGSize?]
    ) {
        let frames = frames(of: subviews, width: bounds.width, cache: &cache)

        for (subview, frame) in zip(subviews, frames) {
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func frames(
        of subviews: Subviews,
        width: CGFloat,
        cache: inout [CGSize?]
    ) -> [CGRect] {
        var frames: [CGRect] = []
        var origin = CGPoint.zero
        var rowHeight = 0.0

        for index in subviews.indices {
            let size = size(of: subviews[index], at: index, width: width, cache: &cache)

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

    private func size(
        of subview: LayoutSubview,
        at index: Int,
        width: CGFloat,
        cache: inout [CGSize?]
    ) -> CGSize {
        let size = cache[index] ?? subview.sizeThatFits(.unspecified)
        cache[index] = size

        guard size.width > width else {
            return size
        }

        // Too wide to stand on its own line, so it is measured again against the width it has.
        return subview.sizeThatFits(ProposedViewSize(width: width, height: nil))
    }
}
