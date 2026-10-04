import DesignSystem
import SwiftUI

/// The count of the timers behind the front one, poking out of the stack's corner, gone early in the opening before
/// the timers behind come out from under the front one.
struct RunningTimersCountBadge: View {
    // Where along the opening the count is gone.
    private static let fadeEnd = 0.3

    private let count: Int
    private let openness: Double

    /// - Parameters:
    ///   - count: How many timers lie behind the front one.
    ///   - openness: How far the timers are open, from 0 stacked to 1 listed.
    init(
        count: Int,
        openness: Double
    ) {
        self.count = count
        self.openness = openness
    }

    var body: some View {
        Text(verbatim: "+\(count)")
            .contentTransition(.numericText())
            .font(.caption.weight(.bold))
            .monospacedDigit()
            .foregroundStyle(.white)
            .padding(.horizontal, SousSpacing.small)
            .padding(.vertical, SousSpacing.hairline)
            .background(.accent, in: Capsule())
            .offset(x: SousSpacing.xSmall, y: -SousSpacing.small)
            .runningTimersFade(
                openness: openness,
                over: 0.0...Self.fadeEnd,
                fadesOut: true
            )
            .accessibilityHidden(true)
    }
}

#Preview("Running timers count badge") {
    @Previewable @State var count = 2

    VStack(spacing: SousSpacing.large) {
        Stepper(
            value: $count,
            in: 1...12,
            label: { Text(verbatim: "Behind") }
        )

        RunningTimersCountBadge(count: count, openness: 0.0)
    }
    .padding()
    .animation(.runningTimers, value: count)
}
