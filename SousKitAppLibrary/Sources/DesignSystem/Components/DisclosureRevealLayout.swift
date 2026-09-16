import SwiftUI

/// Takes up the top part of its content's height, so what follows moves with the content's lower edge.
struct DisclosureRevealLayout: Layout {
    /// The part of the height taken up, from 0 for none to 1 for all of it.
    var progress: Double

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache _: inout ()
    ) -> CGSize {
        guard let subview = subviews.first else {
            return .zero
        }

        let size = subview.sizeThatFits(proposal)

        return CGSize(width: size.width, height: size.height * progress)
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
            proposal: proposal
        )
    }
}
