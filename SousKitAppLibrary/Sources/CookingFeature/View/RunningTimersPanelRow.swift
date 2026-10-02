import DesignSystem
import SwiftUI

/// One running timer as the panel shows it: showing what it is once it is out from behind another, and fading as it
/// scrolls under the room above the list.
struct RunningTimersPanelRow: View {
    /// How a timer comes and goes: up from the bottom, and out in its place, so the timers around it close the gap.
    ///
    /// The same for every timer, since SwiftUI keeps the transition a timer came in with for when it goes.
    static let transition = AnyTransition.asymmetric(
        insertion: .move(edge: .bottom).combined(with: .opacity),
        removal: .runningTimerLeaving
    )

    // How far past its edges the fade lets the timer draw, so the fade cuts off nothing but what scrolls under the
    // room.
    private static let overhang = 200.0

    // Where along the opening a timer behind the front one starts showing what it is, once no other lies over its
    // text, and where its text is fully there.
    private static let contentFadeStart = 0.65
    private static let contentFadeEnd = 1.0

    // Where along the opening a timer stacked out of sight behind the last shown is fully there.
    private static let hiddenFadeEnd = 0.3

    private let presenter: CookingFeaturePresenterProtocol
    private let motion: RunningTimersMotion
    private let timer: RunningTimer
    private let depth: Int
    private let width: CGFloat
    private let isConfirmingCancel: Bool
    private let isListed: Bool
    private let opensOnTap: Bool
    private let isSwooping: Bool
    private let fadeTop: CGFloat
    private let fadeHeight: CGFloat
    private let openness: Double

    /// - Parameters:
    ///   - openness: How far the timers are open, from 0 stacked to 1 listed.
    ///   - depth: How many timers lie before this one.
    ///   - width: How wide the timer is once listed, which it lays what it shows out at all along.
    ///   - isListed: Whether the timers are listed, when every one takes taps and is read out, rather than stacked
    ///     behind the front one.
    ///   - opensOnTap: Whether tapping the timer opens the list, which the front of a stack does.
    ///   - isSwooping: Whether the timer is on its swoop from the front to its place, showing itself on its way.
    ///   - fadeTop: Where in the region the timers start fading as they scroll up.
    ///   - fadeHeight: How far below that the fade runs.
    init(
        presenter: CookingFeaturePresenterProtocol,
        motion: RunningTimersMotion,
        openness: Double,
        timer: RunningTimer,
        depth: Int,
        width: CGFloat,
        isConfirmingCancel: Bool,
        isListed: Bool,
        opensOnTap: Bool,
        isSwooping: Bool,
        fadeTop: CGFloat,
        fadeHeight: CGFloat
    ) {
        self.presenter = presenter
        self.motion = motion
        self.openness = openness
        self.timer = timer
        self.depth = depth
        self.width = width
        self.isConfirmingCancel = isConfirmingCancel
        self.isListed = isListed
        self.opensOnTap = opensOnTap
        self.isSwooping = isSwooping
        self.fadeTop = fadeTop
        self.fadeHeight = fadeHeight
    }

    var body: some View {
        RunningTimerRow(
            presenter: presenter,
            timer: timer,
            isConfirmingCancel: isConfirmingCancel,
            contentWidth: width,
            contentFade: RunningTimersFade(
                openness: openness,
                over: Self.contentFadeStart...Self.contentFadeEnd,
                isEnabled: depth > 0 && !isSwooping
            )
        )
        .mask {
            scrollFade
        }
        .runningTimersFade(
            openness: openness,
            over: 0.0...Self.hiddenFadeEnd,
            isEnabled: depth > RunningTimersLayout.shownDepth && !isSwooping
        )
        .contentShape(.rect)
        .onTapGesture(perform: open)
        .allowsHitTesting(depth == 0 || isListed)
        .accessibilityElement(children: .contain)
        .accessibilityHidden(depth > 0 && !isListed)
        .accessibilityAddTraits(.isButton)
        .accessibilityRemoveTraits(opensOnTap ? [] : .isButton)
        .accessibilityActions {
            showAllAction
        }
    }

    @ViewBuilder
    private var showAllAction: some View {
        if opensOnTap {
            Button(action: open, label: { Text("Show all timers", bundle: .module) })
        }
    }

    // The timers are glass, which the system's scroll edge effect leaves as it is, so a timer fades by a mask of its
    // own as it scrolls into the room above the list, which stays where it is on the screen as the timer scrolls.
    private var scrollFade: some View {
        GeometryReader { proxy in
            let bandTop = motion.scrollOffset + fadeTop
                - proxy.frame(in: .named(RunningTimersPanelContent.coordinateSpace)).minY

            VStack(spacing: 0.0) {
                LinearGradient(
                    colors: [.clear, .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: fadeHeight)

                Color.black
            }
            .frame(
                width: proxy.size.width + 2.0 * Self.overhang,
                height: max(0.0, proxy.size.height + Self.overhang - bandTop)
            )
            .offset(x: -Self.overhang, y: bandTop)
        }
    }

    private func open() {
        guard opensOnTap else {
            return
        }

        presenter.didOpenTimerList()
    }
}

#Preview("Running timers panel row") {
    RunningTimersPanelRow(
        presenter: CookingFeaturePresenterStub(),
        motion: RunningTimersMotion(),
        openness: 0.0,
        timer: RunningTimer(
            id: UUID(),
            stepTimer: StepTimer(stepNumber: 3, text: "15 min", duration: .seconds(900)),
            endDate: .now.addingTimeInterval(260),
            isRinging: false
        ),
        depth: 0,
        width: 370.0,
        isConfirmingCancel: false,
        isListed: false,
        opensOnTap: true,
        isSwooping: false,
        fadeTop: 0.0,
        fadeHeight: 52.0
    )
    .padding()
    .coordinateSpace(.named(RunningTimersPanelContent.coordinateSpace))
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .sousPage()
}
