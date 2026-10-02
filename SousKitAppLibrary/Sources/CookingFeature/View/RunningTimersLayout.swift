import DesignSystem
import SwiftUI

/// Lays the running timers out between their stack and their list, by how far open they are, with the button that
/// folds the list back above them.
///
/// Every timer has a place in both, the ones stacked out of sight behind the last shown too, so each travels between
/// its two places as the timers open and fold. The layout measures the whole panel: the region it is given at least,
/// and taller once the list outgrows the region and scrolls.
struct RunningTimersLayout: Layout {
    /// What a subview is to the layout.
    enum Role {
        case timer
        case collapseButton

        /// The count of the timers behind the front one, at the front one's corner.
        case countBadge

        /// What lies over the room the timers scroll into and whatever is above it, taking the taps there.
        case cover
    }

    /// Where the list sits while it is shorter than the region.
    enum ListAnchor {
        case top
        case bottom
    }

    /// Marks what a subview is to the layout.
    struct RoleKey: LayoutValueKey {
        static let defaultValue = Role.timer
    }

    /// Marks the timer swooping from the front of the stack to its place behind the others.
    struct SwoopingKey: LayoutValueKey {
        static let defaultValue = false
    }

    /// Marks which timer a subview shows, so a swipe can tell which one it lands on.
    struct TimerIDKey: LayoutValueKey {
        static let defaultValue: RunningTimer.ID? = nil
    }

    private struct Measurement {
        let timers: [LayoutSubview]
        let button: LayoutSubview?
        let countBadge: LayoutSubview?
        let cover: LayoutSubview?
        let heights: [CGFloat]
        let stackTop: CGFloat
        let listRoomTop: CGFloat
        let listRowsTop: CGFloat
        let contentHeight: CGFloat
    }

    /// How far down each stacked timer sits from the one before it.
    static let stackStep = SousSpacing.small

    /// How far in from each side each stacked timer sits from the one before it.
    static let stackInset = SousSpacing.medium

    /// How many timers show behind the soonest one.
    static let shownDepth = 2

    /// The gap between listed timers.
    static let spacing = SousSpacing.small

    // How much each gap between listed timers widens for every point they are pulled up past open, so they carry on
    // spreading as they did while opening.
    private static let stretchSpread = 0.1

    private let region: CGSize
    private let topInset: CGFloat
    private let roomHeight: CGFloat
    private let horizontalInset: CGFloat
    private let listAnchor: ListAnchor
    private let scrollOffset: CGFloat
    private let scrollShift: CGFloat
    private let metrics: RunningTimersLayoutMetrics
    private var openness: Double
    private var swoop: Double
    private var rubberBand: CGFloat

    /// - Parameters:
    ///   - openness: How far the timers are open, from 0 stacked to 1 listed.
    ///   - swoop: How far the swooping timer is on its way, from 0 in front to 1 in its place.
    ///   - rubberBand: How far the timers are pulled past where they open or fold to, down for positive values.
    ///   - region: The room the panel shows the timers in.
    ///   - topInset: How far into the region the list may rise.
    ///   - roomHeight: The room kept above the listed timers, for the collapse button and the fade they scroll into.
    ///   - horizontalInset: How far the timers keep from the region's sides.
    ///   - listAnchor: Where the list sits while it is shorter than the region.
    ///   - scrollOffset: How far the list is scrolled down, which the collapse button stays clear of.
    ///   - scrollShift: How far up the list keeps its rows while it folds from a scrolled position.
    ///   - metrics: Where the layout leaves what a swipe needs to know.
    init(
        openness: Double,
        swoop: Double,
        rubberBand: CGFloat,
        region: CGSize,
        topInset: CGFloat,
        roomHeight: CGFloat,
        horizontalInset: CGFloat,
        listAnchor: ListAnchor,
        scrollOffset: CGFloat,
        scrollShift: CGFloat,
        metrics: RunningTimersLayoutMetrics
    ) {
        self.openness = openness
        self.swoop = swoop
        self.rubberBand = rubberBand
        self.region = region
        self.topInset = topInset
        self.roomHeight = roomHeight
        self.horizontalInset = horizontalInset
        self.listAnchor = listAnchor
        self.scrollOffset = scrollOffset
        self.scrollShift = scrollShift
        self.metrics = metrics
    }

    var animatableData: AnimatablePair<AnimatablePair<Double, Double>, CGFloat> {
        get { AnimatablePair(AnimatablePair(openness, swoop), rubberBand) }
        set {
            openness = newValue.first.first
            swoop = newValue.first.second
            rubberBand = newValue.second
        }
    }

    /// How tall a stack of timers stands.
    ///
    /// - Parameters:
    ///   - frontHeight: How tall the soonest timer is.
    ///   - count: How many timers are running.
    /// - Returns: The stack's height, zero without timers.
    static func stackHeight(frontHeight: CGFloat, count: Int) -> CGFloat {
        guard count > 0 else {
            return 0.0
        }

        return frontHeight + stackStep * CGFloat(min(count - 1, shownDepth))
    }

    func sizeThatFits(
        proposal _: ProposedViewSize,
        subviews: Subviews,
        cache _: inout ()
    ) -> CGSize {
        CGSize(width: region.width, height: measure(subviews).contentHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal _: ProposedViewSize,
        subviews: Subviews,
        cache _: inout ()
    ) {
        let measured = measure(subviews)

        metrics.update(
            foldDistance: max(1.0, measured.stackTop - measured.listRowsTop),
            presentedOpenness: clampedOpenness,
            presentedRubberBand: rubberBand
        )

        var timerFrames: [(id: RunningTimer.ID, frame: CGRect)] = []

        for (depth, timer) in measured.timers.enumerated() {
            let stacked = timer[SwoopingKey.self] ? swoopRect(depth, in: measured) : stackRect(depth, in: measured)
            let rect = between(stacked, and: listRect(depth, in: measured))
            let origin = CGPoint(x: bounds.minX + rect.minX, y: bounds.minY + rubberBand + rect.minY)

            timer.place(
                at: origin,
                anchor: .topLeading,
                proposal: ProposedViewSize(rect.size)
            )

            if let id = timer[TimerIDKey.self] {
                timerFrames.append((id: id, frame: CGRect(origin: origin, size: rect.size)))
            }
        }

        metrics.update(timerFrames: timerFrames)

        if let countBadge = measured.countBadge, !measured.timers.isEmpty {
            let front = between(stackRect(0, in: measured), and: listRect(0, in: measured))

            countBadge.place(
                at: CGPoint(x: bounds.minX + front.maxX, y: bounds.minY + rubberBand + front.minY),
                anchor: .topTrailing,
                proposal: .unspecified
            )
        }

        if let button = measured.button {
            let rect = between(stackedButtonRect(button, in: measured), and: listedButtonRect(button, in: measured))

            button.place(
                at: CGPoint(x: bounds.minX + rect.minX, y: bounds.minY + rubberBand + rect.minY),
                anchor: .topLeading,
                proposal: ProposedViewSize(rect.size)
            )
        }

        // Kept at the top of what is on screen, over the timers that have scrolled up under the room and faded.
        measured.cover?.place(
            at: CGPoint(x: bounds.minX, y: bounds.minY + scrollOffset),
            anchor: .topLeading,
            proposal: ProposedViewSize(width: region.width, height: topInset + roomHeight)
        )
    }

    private var clampedOpenness: Double {
        min(1.0, max(0.0, openness))
    }

    private var rowWidth: CGFloat {
        region.width - 2.0 * horizontalInset
    }

    private func measure(_ subviews: Subviews) -> Measurement {
        let timers = subviews.filter({ $0[RoleKey.self] == .timer })
        let heights = timers.map({ $0.sizeThatFits(ProposedViewSize(width: rowWidth, height: nil)).height })
        let rowsHeight = heights.reduce(0.0, +) + Self.spacing * CGFloat(max(0, timers.count - 1))
        let stackHeight = Self.stackHeight(frontHeight: heights.first ?? 0.0, count: timers.count)
        let listRoomTop = switch listAnchor {
        case .top: topInset
        case .bottom: max(topInset, region.height - roomHeight - rowsHeight)
        }

        return Measurement(
            timers: timers,
            button: subviews.first(where: { $0[RoleKey.self] == .collapseButton }),
            countBadge: subviews.first(where: { $0[RoleKey.self] == .countBadge }),
            cover: subviews.first(where: { $0[RoleKey.self] == .cover }),
            heights: heights,
            stackTop: region.height - stackHeight,
            listRoomTop: listRoomTop,
            listRowsTop: listRoomTop + roomHeight,
            contentHeight: max(region.height, listRoomTop + roomHeight + rowsHeight)
        )
    }

    private func stackRect(_ depth: Int, in measured: Measurement) -> CGRect {
        let level = CGFloat(min(depth, Self.shownDepth))

        return CGRect(
            x: horizontalInset + Self.stackInset * level,
            y: measured.stackTop + Self.stackStep * level,
            width: rowWidth - 2.0 * Self.stackInset * level,
            height: measured.heights.first ?? 0.0
        )
    }

    // One curve from the front over the top of the stack and down into the timer's place, halfway along just above
    // the soonest timer and clear of the stack, where it passes from in front of the others to behind them.
    private func swoopRect(_ depth: Int, in measured: Measurement) -> CGRect {
        let start = stackRect(0, in: measured)
        let end = stackRect(depth, in: measured)
        let top = start.offsetBy(dx: 0.0, dy: -(start.height + Self.spacing))

        func along(_ value: (CGRect) -> CGFloat) -> CGFloat {
            let control = 2.0 * value(top) - (value(start) + value(end)) / 2.0
            let remaining = 1.0 - swoop

            return remaining * remaining * value(start) + 2.0 * remaining * swoop * control + swoop * swoop * value(end)
        }

        return CGRect(x: along(\.minX), y: along(\.minY), width: along(\.width), height: along(\.height))
    }

    private func listRect(_ depth: Int, in measured: Measurement) -> CGRect {
        let above = measured.heights.prefix(depth).reduce(0.0, +) + Self.spacing * CGFloat(depth)

        let below = CGFloat(measured.timers.count - 1 - depth)

        return CGRect(
            x: horizontalInset,
            y: measured.listRowsTop - scrollShift + above - stretchGap * below,
            width: rowWidth,
            height: measured.heights[depth]
        )
    }

    private func stackedButtonRect(_ button: LayoutSubview, in measured: Measurement) -> CGRect {
        let size = button.sizeThatFits(.unspecified)

        return CGRect(
            x: horizontalInset + rowWidth - size.width,
            y: measured.stackTop - roomHeight,
            width: size.width,
            height: size.height
        )
    }

    // Kept above the rows as they scroll under it, so it takes the scrolling back that the rows undergo. It spreads
    // from the soonest as the rows spread from each other.
    private func listedButtonRect(_ button: LayoutSubview, in measured: Measurement) -> CGRect {
        let size = button.sizeThatFits(.unspecified)
        let spread = stretchGap * CGFloat(measured.timers.count)

        return CGRect(
            x: horizontalInset + rowWidth - size.width,
            y: measured.listRoomTop + scrollOffset - spread,
            width: size.width,
            height: size.height
        )
    }

    // How much wider each gap between listed timers stands, for how far they are pulled up past open.
    private var stretchGap: CGFloat {
        max(0.0, -rubberBand) * Self.stretchSpread
    }

    // Unclamped, so a spring that overshoots carries the timers past their places and back.
    private func between(_ stacked: CGRect, and listed: CGRect) -> CGRect {
        CGRect(
            x: stacked.minX + (listed.minX - stacked.minX) * openness,
            y: stacked.minY + (listed.minY - stacked.minY) * openness,
            width: stacked.width + (listed.width - stacked.width) * openness,
            height: stacked.height + (listed.height - stacked.height) * openness
        )
    }
}

private func previewStack(openness: Double) -> some View {
    RunningTimersLayout(
        openness: openness,
        swoop: 0.0,
        rubberBand: 0.0,
        region: CGSize(width: 360.0, height: 500.0),
        topInset: 0.0,
        roomHeight: 52.0,
        horizontalInset: SousSpacing.large,
        listAnchor: .bottom,
        scrollOffset: 0.0,
        scrollShift: 0.0,
        metrics: RunningTimersLayoutMetrics()
    ) {
        ForEach(0..<4) { depth in
            RoundedRectangle(cornerRadius: SousRadius.large)
                .fill(.background)
                .stroke(.separator)
                .frame(height: 60.0)
                .zIndex(-Double(depth))
        }

        Circle()
            .fill(.background)
            .stroke(.separator)
            .frame(width: 44.0, height: 44.0)
            .layoutValue(key: RunningTimersLayout.RoleKey.self, value: .collapseButton)
    }
}

#Preview("Running timers layout") {
    @Previewable @State var openness = 0.0

    VStack {
        Slider(value: $openness)
            .padding()

        previewStack(openness: openness)
            .frame(
                width: 360.0,
                height: 500.0,
                alignment: .top
            )
    }
    .background(.groupedBackground)
}
