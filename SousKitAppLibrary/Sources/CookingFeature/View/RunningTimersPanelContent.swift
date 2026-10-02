import DesignSystem
import SwiftUI

/// The running timers as the panel lays them out: a stack opening into a list, with the button that folds it back,
/// or a column of them all.
///
/// The view is as tall as the panel's region at least, and taller once the list outgrows it; the panel scrolls it.
struct RunningTimersPanelContent: View {
    /// The coordinate space of the whole content, which a timer reads its place in as it scrolls.
    static let coordinateSpace = "runningTimersPanel"

    // The room kept above the listed timers: a toolbar button's size and the gap under it where the list folds, or
    // the run the timers fade out over where it is always open.
    private static let collapseRoomHeight = GlassCircleButtonStyle.diameter + SousSpacing.small
    private static let fadeRoomHeight = SousSpacing.large

    private let presenter: CookingFeaturePresenterProtocol
    private let viewModel: CookingFeatureViewModel
    private let motion: RunningTimersMotion
    private let kind: RunningTimersPanel.Kind
    private let region: CGSize
    private let topInset: CGFloat
    private let metrics: RunningTimersLayoutMetrics
    private let onContentHeightChange: (CGFloat) -> Void
    private let onListOpenChange: (Bool) -> CGFloat

    // How tall each timer was last laid out, by timer, since the front one changes without changing its own height.
    @State private var rowHeights: [RunningTimer.ID: CGFloat] = [:]

    // A timer that joined the stack behind the front one, on its way to its place.
    @State private var arrival = RunningTimerArrival()

    /// - Parameters:
    ///   - region: The room the panel shows the timers in.
    ///   - topInset: How far into the region the list may rise.
    ///   - metrics: Where the layout leaves what a swipe needs to know.
    ///   - onContentHeightChange: Reports how tall the content stands, for the panel to scroll.
    ///   - onListOpenChange: Reports the list opening or closing, and returns how far it was scrolled at the time.
    init(
        presenter: CookingFeaturePresenterProtocol,
        viewModel: CookingFeatureViewModel,
        motion: RunningTimersMotion,
        kind: RunningTimersPanel.Kind,
        region: CGSize,
        topInset: CGFloat,
        metrics: RunningTimersLayoutMetrics,
        onContentHeightChange: @escaping (CGFloat) -> Void,
        onListOpenChange: @escaping (Bool) -> CGFloat
    ) {
        self.presenter = presenter
        self.viewModel = viewModel
        self.motion = motion
        self.kind = kind
        self.region = region
        self.topInset = topInset
        self.metrics = metrics
        self.onContentHeightChange = onContentHeightChange
        self.onListOpenChange = onListOpenChange
    }

    var body: some View {
        timers
            .background {
                outsideTapTarget
            }
            .coordinateSpace(.named(Self.coordinateSpace))
            .onGeometryChange(for: CGFloat.self, of: \.size.height, action: onContentHeightChange)
            .animation(.runningTimers, value: viewModel.runningTimers)
            .onChange(of: viewModel.runningTimers, runningTimersDidChange)
            .onChange(of: viewModel.isTimerListOpen, initial: true, listOpenDidChange)
            .task(id: arrival.id) {
                await arrival.takeToItsPlace(isInteracting: isInteracting, isRunning: viewModel.isRunning)
            }
            .onChange(of: stackHeight, initial: true) { _, height in
                motion.stackHeight = height
            }
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(isListOpen ? .isModal : [])
            .accessibilityAction(.escape, close)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .top
            )
    }

    private var timers: some View {
        RunningTimersLayout(
            openness: motion.openness,
            swoop: arrival.swoopProgress,
            rubberBand: motion.rubberBand,
            region: region,
            topInset: topInset,
            roomHeight: roomHeight,
            horizontalInset: horizontalInset,
            listAnchor: kind == .folding ? .bottom : .top,
            scrollOffset: motion.scrollOffset,
            scrollShift: motion.scrollShift,
            metrics: metrics
        ) {
            ForEach(Array(shownTimers.enumerated()), id: \.element.id) { depth, timer in
                row(timer, depth: depth)
            }

            countBadge

            roomCover

            collapseButton
        }
    }

    private func row(_ timer: RunningTimer, depth: Int) -> some View {
        let swoop = arrival.swoop(of: timer.id)
        let swipeOffset = motion.swipeOffsets[timer.id] ?? 0.0

        return RunningTimersPanelRow(
            presenter: presenter,
            motion: motion,
            timer: timer,
            depth: depth,
            width: rowWidth,
            isConfirmingCancel: timer.id == viewModel.timerConfirmingCancel?.id,
            isListed: kind == .column || isListOpen,
            opensOnTap: kind == .folding && depth == 0 && !isListOpen && viewModel.runningTimers.count > 1,
            isSwooping: swoop != nil,
            fadeTop: topInset,
            fadeHeight: roomHeight
        )
        .onGeometryChange(for: CGFloat.self, of: \.size.height) { height in
            rowHeights[timer.id] = height
        }
        .offset(x: swipeOffset)
        // Behind the timer and where it was laid out, so it fills the room the timer leaves.
        .background(alignment: .trailing) {
            RunningTimerSwipeReveal(
                width: min(-swipeOffset, rowWidth),
                threshold: rowWidth * RunningTimersSwipe.threshold,
                isRinging: timer.isRinging
            )
        }
        .runningTimerStacking(depth: depth, swoop: swoop)
        .layoutValue(key: RunningTimersLayout.SwoopingKey.self, value: swoop != nil)
        .layoutValue(key: RunningTimersLayout.TimerIDKey.self, value: timer.id)
        // Outermost, or SwiftUI fades the timer in and out instead.
        .transition(RunningTimersPanelRow.transition)
    }

    // The stack's own rather than the front timer's, so it stays put as another timer comes in front. Under a timer
    // swooping over the stack.
    @ViewBuilder
    private var countBadge: some View {
        if kind == .folding, viewModel.runningTimers.count > 1 {
            RunningTimersCountBadge(count: viewModel.runningTimers.count - 1, openness: motion.openness)
                .layoutValue(key: RunningTimersLayout.RoleKey.self, value: .countBadge)
                .zIndex(0.5)
                .transition(.opacity)
        }
    }

    // A timer scrolled up under the room is faded out, so a tap there counts as one beside the list, not on the timer.
    @ViewBuilder
    private var roomCover: some View {
        if isListOpen {
            closeTapTarget
                .layoutValue(key: RunningTimersLayout.RoleKey.self, value: .cover)
                .zIndex(1.0)
        }
    }

    // VoiceOver closes the list with its escape gesture instead.
    private var closeTapTarget: some View {
        Color.clear
            .contentShape(.rect)
            .onTapGesture(perform: close)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var collapseButton: some View {
        if kind == .folding {
            RunningTimersCollapseButton(openness: motion.openness, isOpen: isListOpen, action: close)
                .layoutValue(key: RunningTimersLayout.RoleKey.self, value: .collapseButton)
                .zIndex(2.0)
        }
    }

    @ViewBuilder
    private var outsideTapTarget: some View {
        if isListOpen {
            closeTapTarget
        }
    }

    private var horizontalInset: CGFloat {
        kind == .folding ? SousSpacing.large : 0.0
    }

    // How wide a listed timer stands, and the soonest one stacked.
    private var rowWidth: CGFloat {
        max(0.0, region.width - 2.0 * horizontalInset)
    }

    private var roomHeight: CGFloat {
        kind == .folding ? Self.collapseRoomHeight : Self.fadeRoomHeight
    }

    private var isListOpen: Bool {
        kind == .folding && viewModel.isTimerListOpen
    }

    private var stackHeight: CGFloat {
        guard kind == .folding else {
            return 0.0
        }

        let frontHeight = shownTimers.first.flatMap({ rowHeights[$0.id] }) ?? 0.0
        return RunningTimersLayout.stackHeight(frontHeight: frontHeight, count: viewModel.runningTimers.count)
    }

    private var shownTimers: [RunningTimer] {
        arrival.shown(viewModel.runningTimers)
    }

    // Only into the folded stack does a timer arrive in front.
    private func runningTimersDidChange(
        from oldTimers: [RunningTimer],
        to newTimers: [RunningTimer]
    ) {
        rowHeights = rowHeights.filter({ id, _ in newTimers.contains(where: { $0.id == id }) })

        if kind == .folding, !isListOpen {
            arrival.timersDidChange(from: oldTimers, to: newTimers)
        }
    }

    private func isInteracting(with id: RunningTimer.ID) -> Bool {
        motion.swipedTimer == id || viewModel.timerConfirmingCancel?.id == id
    }

    // The column is always open. The stack opens and folds on the timers' spring, unless a swipe already set them
    // going.
    private func listOpenDidChange(
        from wasOpen: Bool,
        to isOpen: Bool
    ) {
        guard kind == .folding else {
            motion.openness = 1.0
            return
        }

        // The list shows every timer in its place.
        if isOpen {
            arrival.settle()
        }

        motion.scrollShift = onListOpenChange(isOpen)
        let openness = isOpen ? 1.0 : 0.0

        guard wasOpen != isOpen, motion.openness != openness else {
            motion.openness = openness
            return
        }

        withAnimation(.runningTimers) {
            motion.openness = openness
        }
    }

    private func close() {
        guard isListOpen else {
            return
        }

        presenter.didCloseTimerList()
    }
}

#Preview("Running timers panel content") {
    RunningTimersPanelContent(
        presenter: CookingFeaturePresenterStub(),
        viewModel: RunningTimersPreview.viewModel(isTimerListOpen: true),
        motion: RunningTimersMotion(),
        kind: .folding,
        region: CGSize(width: 402.0, height: 700.0),
        topInset: 0.0,
        metrics: RunningTimersLayoutMetrics(),
        onContentHeightChange: { _ in
            // The preview scrolls nothing.
        },
        onListOpenChange: { _ in 0.0 }
    )
    .frame(width: 402.0, height: 700.0)
    .sousPage()
}
