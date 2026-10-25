import SwiftUI

/// Offers its content a height where none is proposed, and never more than the most it may take, so a
/// `ViewThatFits` in it chooses by that height; it is as tall as what its content takes of it.
struct HeightOffer: Layout {
    let maximumHeight: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache _: inout ()
    ) -> CGSize {
        let height = offeredHeight(proposal)
        let size = subviews.first?.sizeThatFits(ProposedViewSize(width: proposal.width, height: height)) ?? .zero

        return CGSize(width: size.width, height: min(size.height, height))
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache _: inout ()
    ) {
        subviews.first?.place(
            at: bounds.origin,
            anchor: .topLeading,
            proposal: ProposedViewSize(width: bounds.width, height: offeredHeight(proposal))
        )
    }

    private func offeredHeight(_ proposal: ProposedViewSize) -> CGFloat {
        min(proposal.height ?? maximumHeight, maximumHeight)
    }
}
