import SwiftUI

/// Lays cards out on one another, or fanned out from the middle, each as tall as the tallest and as wide as the fan
/// can make them within a range.
///
/// The cards turn themselves, by ``angle`` for each place they sit from the middle. The fan keeps room for where that
/// turn takes them, and the room it fills is wider than the cards where it is offered more.
struct OnboardingFanLayout: Layout {
    /// How far a card turns for each place it sits from the middle, in degrees.
    static let angle = 9.0

    // How far a card moves for each place it sits from the middle, as shares of a card's width.
    private static let spread = 0.42
    private static let drop = 0.06

    private let cardWidths: ClosedRange<Double>
    private let isFanned: Bool

    /// - Parameters:
    ///   - cardWidths: The narrowest and the widest a card can be. Asked for its ideal size, the fan is as wide as
    ///     its narrowest cards make it.
    ///   - isFanned: Whether the cards are fanned out, or lie on one another.
    init(cardWidths: ClosedRange<Double>, isFanned: Bool) {
        self.cardWidths = cardWidths
        self.isFanned = isFanned
    }

    /// Where a card sits in the fan, from the left end at minus half the count less one to the right end at plus.
    ///
    /// - Parameters:
    ///   - index: The card's place among the cards.
    ///   - count: How many cards there are.
    /// - Returns: The position.
    static func position(ofCardAt index: Int, of count: Int) -> Double {
        Double(index) - Double(count - 1) / 2.0
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache _: inout ()
    ) -> CGSize {
        let cardWidth = cardWidth(fitting: proposal.width, count: subviews.count)
        var width = cardWidth * Self.widthShare(of: subviews.count)

        if let proposedWidth = proposal.width, proposedWidth.isFinite {
            width = proposedWidth
        }

        return CGSize(
            width: width,
            height: cardHeight(of: subviews, width: cardWidth) + cardWidth * Self.overhangShare(of: subviews.count)
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal _: ProposedViewSize,
        subviews: Subviews,
        cache _: inout ()
    ) {
        let cardWidth = cardWidth(fitting: bounds.width, count: subviews.count)
        let cardSize = ProposedViewSize(width: cardWidth, height: cardHeight(of: subviews, width: cardWidth))

        for (index, subview) in subviews.enumerated() {
            let position = isFanned ? Self.position(ofCardAt: index, of: subviews.count) : 0.0

            subview.place(
                at: CGPoint(
                    x: bounds.midX + position * Self.spread * cardWidth,
                    y: bounds.minY + abs(position) * Self.drop * cardWidth
                ),
                anchor: .top,
                proposal: cardSize
            )
        }
    }

    // The fan's width in card widths, with a card's turned corner taken as reaching a card's width from its foot.
    private static func widthShare(of count: Int) -> Double {
        let end = position(ofCardAt: count - 1, of: count)
        let turn = Angle.degrees(end * angle).radians

        return 2.0 * (end * spread + 0.5 * cos(turn) + sin(turn))
    }

    // How far the cards at the ends reach below the middle one, in card widths.
    private static func overhangShare(of count: Int) -> Double {
        let end = position(ofCardAt: count - 1, of: count)
        let turn = Angle.degrees(end * angle).radians

        return end * drop + 0.5 * sin(turn)
    }

    private func cardWidth(fitting width: CGFloat?, count: Int) -> Double {
        guard let width else {
            return cardWidths.lowerBound
        }

        return min(max(width / Self.widthShare(of: count), cardWidths.lowerBound), cardWidths.upperBound)
    }

    private func cardHeight(of subviews: Subviews, width: Double) -> Double {
        subviews
            .map({ $0.sizeThatFits(ProposedViewSize(width: width, height: nil)).height })
            .max() ?? 0.0
    }
}
