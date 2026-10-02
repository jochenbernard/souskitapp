import DesignSystem
import SwiftUI

/// Fades a view in or out over a stretch of the way the running timers open, frame by frame as they move.
///
/// Animates how far open the timers are on its own, so a frame of their movement updates the view's opacity alone.
struct RunningTimersFade: ViewModifier, Animatable {
    var animatableData: Double

    private let range: ClosedRange<Double>
    private let fadesOut: Bool
    private let isEnabled: Bool

    /// - Parameters:
    ///   - openness: How far the timers are open, from 0 stacked to 1 listed.
    ///   - range: The stretch of the opening the view fades over.
    ///   - fadesOut: Whether the view fades out as the timers open, rather than in.
    ///   - isEnabled: Whether the view fades at all.
    nonisolated init(
        openness: Double,
        over range: ClosedRange<Double>,
        fadesOut: Bool = false,
        isEnabled: Bool = true
    ) {
        self.animatableData = openness
        self.range = range
        self.fadesOut = fadesOut
        self.isEnabled = isEnabled
    }

    /// Whether the view is out of sight once the timers are as far open as they are headed.
    var isHidden: Bool {
        opacity <= 0.0
    }

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
    }

    private var opacity: Double {
        guard isEnabled else {
            return 1.0
        }

        let amount = min(1.0, max(0.0, (animatableData - range.lowerBound) / (range.upperBound - range.lowerBound)))
        return fadesOut ? 1.0 - amount : amount
    }
}

extension View {
    /// Fades the view in or out over a stretch of the way the running timers open.
    ///
    /// - Parameters:
    ///   - openness: How far the timers are open, from 0 stacked to 1 listed.
    ///   - range: The stretch of the opening the view fades over.
    ///   - fadesOut: Whether the view fades out as the timers open, rather than in.
    ///   - isEnabled: Whether the view fades at all.
    /// - Returns: The view, fading as the timers open.
    func runningTimersFade(
        openness: Double,
        over range: ClosedRange<Double>,
        fadesOut: Bool = false,
        isEnabled: Bool = true
    ) -> some View {
        modifier(RunningTimersFade(openness: openness, over: range, fadesOut: fadesOut, isEnabled: isEnabled))
    }
}

#Preview("Running timers fade") {
    @Previewable @State var isOpen = false

    VStack(spacing: SousSpacing.large) {
        Toggle(isOn: $isOpen, label: { Text(verbatim: "Open") })

        Text(verbatim: "Fades in")
            .runningTimersFade(openness: isOpen ? 1.0 : 0.0, over: 0.65...1.0)

        Text(verbatim: "Fades out")
            .runningTimersFade(openness: isOpen ? 1.0 : 0.0, over: 0.0...0.3, fadesOut: true)
    }
    .padding()
    .animation(.runningTimers, value: isOpen)
}
