import DesignSystem
import SwiftUI

/// The running timers over the steps: a stack that opens into a list on a narrow screen, or a column beside them on
/// a wide one, scrolling once they outgrow their room.
///
/// The room is a scroll view of UIKit's, holding ``RunningTimersPanelContent``: a swipe down that scrolls the open
/// list to its top carries straight on into folding it, at the finger's pace and with nothing bouncing, and touches
/// beside the folded stack fall through to the steps. SwiftUI's scroll view neither hands a swipe over mid-way nor
/// holds its bounce back, and takes every touch in its frame.
struct RunningTimersPanel: UIViewRepresentable {
    /// How the panel shows the timers.
    enum Kind {
        /// A stack over the steps that opens into a list.
        case folding

        /// A list beside the steps, always open.
        case column
    }

    private let presenter: CookingFeaturePresenterProtocol
    private let viewModel: CookingFeatureViewModel
    private let motion: RunningTimersMotion
    private let kind: Kind
    private let topInset: CGFloat

    /// - Parameters:
    ///   - motion: Where the timers stand between their stack and their list, which the panel moves.
    ///   - kind: How the panel shows the timers.
    ///   - topInset: How far into the panel the list may rise.
    init(
        presenter: CookingFeaturePresenterProtocol,
        viewModel: CookingFeatureViewModel,
        motion: RunningTimersMotion,
        kind: Kind,
        topInset: CGFloat
    ) {
        self.presenter = presenter
        self.viewModel = viewModel
        self.motion = motion
        self.kind = kind
        self.topInset = topInset
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            presenter: presenter,
            viewModel: viewModel,
            motion: motion,
            kind: kind
        )
    }

    func makeUIView(context: Context) -> RunningTimersScrollView {
        context.coordinator.scrollView
    }

    func updateUIView(_: RunningTimersScrollView, context: Context) {
        context.coordinator.topInset = topInset
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView _: RunningTimersScrollView,
        context _: Context
    ) -> CGSize? {
        proposal.replacingUnspecifiedDimensions()
    }
}

#Preview("Running timers panel") {
    RunningTimersPanel(
        presenter: CookingFeaturePresenterStub(),
        viewModel: RunningTimersPreview.viewModel(isTimerListOpen: false),
        motion: RunningTimersMotion(),
        kind: .folding,
        topInset: 0.0
    )
    .sousPage()
}
