import DesignSystem
import SwiftUI

/// Fades a view as `RunningTimersFade` does, reading how far the timers are open itself, so a frame of a swipe
/// updates the fade alone rather than the view it fades.
struct RunningTimersMotionFade: ViewModifier {
    /// Leaves the view as it is.
    static let disabled = RunningTimersMotionFade(
        motion: RunningTimersMotion(),
        over: 0.0...1.0,
        isEnabled: false
    )

    /// Whether the view is out of sight once the timers are as far open as they are headed.
    let isHidden: Bool

    private let motion: RunningTimersMotion
    private let range: ClosedRange<Double>
    private let isEnabled: Bool

    /// - Parameters:
    ///   - motion: How far the timers are open.
    ///   - range: The stretch of the opening the view fades in over.
    ///   - isEnabled: Whether the view fades at all.
    init(
        motion: RunningTimersMotion,
        over range: ClosedRange<Double>,
        isEnabled: Bool
    ) {
        self.motion = motion
        self.range = range
        self.isEnabled = isEnabled
        self.isHidden = RunningTimersFade(
            openness: motion.openness,
            over: range,
            isEnabled: isEnabled
        ).isHidden
    }

    func body(content: Content) -> some View {
        content
            .runningTimersFade(
                openness: motion.openness,
                over: range,
                isEnabled: isEnabled
            )
    }
}

extension View {
    /// Fades the view in over a stretch of the way the running timers open, reading how far they are open itself.
    ///
    /// - Parameters:
    ///   - motion: How far the timers are open.
    ///   - range: The stretch of the opening the view fades in over.
    ///   - isEnabled: Whether the view fades at all.
    /// - Returns: The view, fading in as the timers open.
    func runningTimersFade(
        motion: RunningTimersMotion,
        over range: ClosedRange<Double>,
        isEnabled: Bool = true
    ) -> some View {
        modifier(
            RunningTimersMotionFade(
                motion: motion,
                over: range,
                isEnabled: isEnabled
            )
        )
    }
}

#Preview("Running timers motion fade") {
    @Previewable @State var motion = RunningTimersMotion()

    VStack(spacing: SousSpacing.large) {
        Button(
            action: {
                withAnimation(.runningTimers) {
                    motion.openness = 1.0 - motion.openness
                }
            },
            label: { Text(verbatim: "Toggle") }
        )

        Text(verbatim: "Fades in")
            .runningTimersFade(motion: motion, over: 0.65...1.0)
    }
    .padding()
}
