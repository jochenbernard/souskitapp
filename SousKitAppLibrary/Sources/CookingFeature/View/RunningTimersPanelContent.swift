import DesignSystem
import SwiftUI

/// The running timers as the panel lays them out: a stack opening into a list, with the button that folds it back,
/// or a column of them all.
///
/// The view is as tall as the panel's region at least, and taller once the list outgrows it; the panel scrolls it.
struct RunningTimersPanelContent: View {
    // Where a timer that joins the folded stack behind the front one is on its way to its place.
    private struct Arrival: Equatable {
        let id: RunningTimer.ID

        /// How far it is on its swoop from the front to its place, from 0 shown in front to 1 in its place, or `nil`
        /// while it is shown in front for a moment, so its start is seen.
        var swoop: Double?
    }

    /// The coordinate space of the whole content, which a timer reads its place in as it scrolls.
    static let coordinateSpace = "runningTimersPanel"

    // The room kept above the listed timers: a toolbar button's size and the gap under it where the list folds, or
    // the run the timers fade out over where it is always open.
    private static let collapseRoomHeight = 44.0 + SousSpacing.small
    private static let fadeRoomHeight = SousSpacing.large

    // How long a timer that joins the stack behind the front one shows in front before it swoops to its place, and how
    // long the swoop takes.
    private static let inFrontDuration = Duration.seconds(1.2)
    private static let swoopDuration = Duration.seconds(Animation.runningTimerSwoopDuration)

    private let presenter: CookingFeaturePresenterProtocol
    private let viewModel: CookingFeatureViewModel
    private let motion: RunningTimersMotion
    private let kind: RunningTimersPanel.Kind
    private let region: CGSize
    private let topInset: CGFloat
    private let metrics: RunningTimersLayoutMetrics
    private let onContentHeightChange: (CGFloat) -> Void
    private let onListOpenChange: (Bool) -> CGFloat

    // How tall the soonest timer is, which sets how tall the stack stands.
    @State private var frontHeight = 0.0

    // A timer that joined the stack behind the front one, on its way to its place.
    @State private var arrival: Arrival?

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
            .task(id: arrival?.id, takeArrivalToItsPlace)
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
            swoop: arrival?.swoop ?? 0.0,
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
        let swoop = arrival?.id == timer.id ? arrival?.swoop : nil

        return RunningTimersPanelRow(
            presenter: presenter,
            motion: motion,
            openness: motion.openness,
            timer: timer,
            depth: depth,
            width: max(0.0, region.width - 2.0 * horizontalInset),
            isConfirmingCancel: timer.id == viewModel.timerConfirmingCancel?.id,
            isListed: kind == .column || isListOpen,
            opensOnTap: kind == .folding && depth == 0 && !isListOpen && viewModel.runningTimers.count > 1,
            isSwooping: swoop != nil,
            fadeTop: topInset,
            fadeHeight: roomHeight
        )
        .onGeometryChange(for: CGFloat.self, of: \.size.height) { height in
            if depth == 0 {
                frontHeight = height
            }
        }
        .runningTimerStacking(depth: depth, swoop: swoop)
        .layoutValue(key: RunningTimersLayout.SwoopingKey.self, value: swoop != nil)
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
            Color.clear
                .contentShape(.rect)
                .onTapGesture(perform: close)
                .accessibilityHidden(true)
                .layoutValue(key: RunningTimersLayout.RoleKey.self, value: .cover)
                .zIndex(1.0)
        }
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
            Color.clear
                .contentShape(.rect)
                // VoiceOver closes the list with its escape gesture instead.
                .onTapGesture(perform: close)
                .accessibilityHidden(true)
        }
    }

    private var horizontalInset: CGFloat {
        kind == .folding ? SousSpacing.large : 0.0
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

        return RunningTimersLayout.stackHeight(frontHeight: frontHeight, count: viewModel.runningTimers.count)
    }

    // Soonest first, but for a timer shown in front for a moment.
    private var shownTimers: [RunningTimer] {
        var shown = viewModel.runningTimers

        guard
            let arrival,
            arrival.swoop == nil,
            let index = shown.firstIndex(where: { $0.id == arrival.id })
        else {
            return shown
        }

        shown.insert(shown.remove(at: index), at: 0)
        return shown
    }

    // A timer that joins the folded stack behind the front one comes in front instead. The timers on screen as the
    // view appears arrive all at once, so only timers joining others count.
    private func runningTimersDidChange(
        from oldTimers: [RunningTimer],
        to newTimers: [RunningTimer]
    ) {
        guard kind == .folding, !isListOpen, !oldTimers.isEmpty else {
            return
        }

        let joining = newTimers.enumerated().last { depth, timer in
            depth > 0 && !oldTimers.contains(where: { $0.id == timer.id })
        }

        if let joining {
            withAnimation(.runningTimers) {
                arrival = Arrival(id: joining.element.id)
            }
        }
    }

    private func takeArrivalToItsPlace() async {
        guard arrival != nil, await pause(for: Self.inFrontDuration) else {
            return
        }

        // From 0, where the swoop starts in front, the same as where the timer is shown.
        withAnimation(.runningTimerSwoop) {
            arrival?.swoop = 1.0
        }

        guard await pause(for: Self.swoopDuration) else {
            return
        }

        withAnimation(.runningTimers) {
            arrival = nil
        }
    }

    // Whether the pause ran its course, rather than a new arrival or the list opening cutting it short.
    private func pause(for duration: Duration) async -> Bool {
        (try? await Task.sleep(for: duration)) != nil
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
            arrival = nil
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
