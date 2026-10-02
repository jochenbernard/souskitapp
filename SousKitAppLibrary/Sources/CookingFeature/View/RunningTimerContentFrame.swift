import SwiftUI

/// Lays a running timer's content out at one width, centred in a box of whatever size the timer is given.
///
/// A box that changes size as the timers move then leaves its content's layout and text as they are.
struct RunningTimerContentFrame: Layout {
    private let width: CGFloat

    /// - Parameter width: The width the content is laid out at.
    init(width: CGFloat) {
        self.width = width
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache _: inout ()
    ) -> CGSize {
        let size = subviews.first?.sizeThatFits(contentProposal) ?? .zero

        return CGSize(width: proposal.width ?? size.width, height: proposal.height ?? size.height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal _: ProposedViewSize,
        subviews: Subviews,
        cache _: inout ()
    ) {
        subviews.first?.place(
            at: CGPoint(x: bounds.midX, y: bounds.midY),
            anchor: .center,
            proposal: contentProposal
        )
    }

    private var contentProposal: ProposedViewSize {
        ProposedViewSize(width: width, height: nil)
    }
}

#Preview("Running timer content frame") {
    RunningTimerContentFrame(width: 200.0) {
        Text(verbatim: "Whisk the eggs with the cream until smooth.")
    }
    .frame(width: 120.0, height: 80.0)
    .border(.separator)
}
