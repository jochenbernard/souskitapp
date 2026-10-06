import CoreGraphics

/// How far content goes past an end for a finger pulling it there, as UIKit's scroll view gives: less and less the
/// further, never as far as the scroll view is long.
enum RubberBand {
    private static let stiffness = 0.55

    /// How far content goes for a pull past an end.
    ///
    /// - Parameters:
    ///   - pull: How far the finger has pulled past the end.
    ///   - dimension: How long the scroll view is along the pull.
    /// - Returns: How far the content goes.
    static func offset(forPull pull: CGFloat, dimension: CGFloat) -> CGFloat {
        let length = max(1.0, dimension)
        return (1.0 - 1.0 / (pull * stiffness / length + 1.0)) * length
    }

    /// How far content goes for a finger at a position along a range, past either end of it.
    ///
    /// - Parameters:
    ///   - position: Where the finger has taken the content to.
    ///   - range: Where the content follows the finger as far as it goes.
    ///   - dimension: How long the scroll view is along the pull.
    /// - Returns: How far the content goes past the range, up for negative values, or nothing within it.
    static func offset(
        at position: CGFloat,
        pastEitherEndOf range: ClosedRange<CGFloat>,
        dimension: CGFloat
    ) -> CGFloat {
        if position < range.lowerBound {
            -offset(forPull: range.lowerBound - position, dimension: dimension)
        } else if position > range.upperBound {
            offset(forPull: position - range.upperBound, dimension: dimension)
        } else {
            0.0
        }
    }

    /// How far a finger pulls for content to have gone a distance past an end, the other way around from
    /// ``offset(forPull:dimension:)``.
    ///
    /// - Parameters:
    ///   - offset: How far the content has gone past the end.
    ///   - dimension: How long the scroll view is along the pull.
    /// - Returns: How far the finger pulls.
    static func pull(forOffset offset: CGFloat, dimension: CGFloat) -> CGFloat {
        let length = max(1.0, dimension)
        let gone = min(offset, length - 1.0)
        return gone * length / (stiffness * (length - gone))
    }
}
