import SwiftUI

/// Lays views out in rows, starting a new row where the next view does not fit.
public struct SousFlowLayout: Layout {
    private let spacing: CGFloat
    private let maximumRowCount: Int?

    /// Creates a flow layout.
    ///
    /// - Parameters:
    ///   - spacing: The gap between two views in a row, and between two rows.
    ///   - maximumRowCount: The most rows the views are meant to take, which makes the layout's ideal width the
    ///     narrowest that holds them in that many, or `nil` for the width of one row.
    public init(spacing: CGFloat, maximumRowCount: Int? = nil) {
        self.spacing = spacing
        self.maximumRowCount = maximumRowCount
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
        let width = proposal.width ?? idealWidth(of: subviews, cache: &cache)

        for frame in frames(of: subviews, width: width, cache: &cache) {
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

    private func idealWidth(of subviews: Subviews, cache: inout [CGSize?]) -> CGFloat {
        guard let maximumRowCount else {
            return .infinity
        }

        let sizes = subviews.indices.map { index in
            size(of: subviews[index], at: index, width: .infinity, cache: &cache)
        }

        return Self.narrowestWidth(
            of: sizes,
            spacing: spacing,
            rowCount: maximumRowCount
        )
    }

    private func frames(
        of subviews: Subviews,
        width: CGFloat,
        cache: inout [CGSize?]
    ) -> [CGRect] {
        let sizes = subviews.indices.map { index in
            size(of: subviews[index], at: index, width: width, cache: &cache)
        }

        return Self.frames(
            of: sizes,
            width: width,
            spacing: spacing
        )
    }

    /// The narrowest width that lays views of the sizes given out in at most a number of rows, to half a point.
    static func narrowestWidth(
        of sizes: [CGSize],
        spacing: CGFloat,
        rowCount: Int
    ) -> CGFloat {
        // Never narrower than the widest view, which a narrower width would measure again.
        let widest = sizes.map(\.width).max() ?? 0.0

        guard Self.rowCount(of: sizes, width: widest, spacing: spacing) > rowCount else {
            return widest
        }

        var tooNarrow = widest
        var wideEnough = sizes.reduce(-spacing) { $0 + $1.width + spacing }

        while wideEnough - tooNarrow > 0.5 {
            let width = (tooNarrow + wideEnough) / 2.0

            if Self.rowCount(of: sizes, width: width, spacing: spacing) <= rowCount {
                wideEnough = width
            } else {
                tooNarrow = width
            }
        }

        return wideEnough
    }

    /// How many rows views of the sizes given take in a width.
    static func rowCount(
        of sizes: [CGSize],
        width: CGFloat,
        spacing: CGFloat
    ) -> Int {
        Set(frames(of: sizes, width: width, spacing: spacing).map(\.minY)).count
    }

    private static func frames(
        of sizes: [CGSize],
        width: CGFloat,
        spacing: CGFloat
    ) -> [CGRect] {
        var frames: [CGRect] = []
        var origin = CGPoint.zero
        var rowHeight = 0.0

        for size in sizes {
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
