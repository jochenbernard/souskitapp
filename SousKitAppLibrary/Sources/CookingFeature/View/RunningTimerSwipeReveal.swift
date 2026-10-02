import DesignSystem
import SwiftUI

/// What swiping a running timer away does, shown in the room the timer leaves as it slides: cancelling it, or
/// stopping one that rings.
///
/// It fades in with the swipe, and goes solid once letting go would take the timer away.
struct RunningTimerSwipeReveal: View {
    // How far the action keeps from the timer sliding past it, and how strong it gets before letting go would do it.
    private static let gap = SousSpacing.small
    private static let unarmedOpacity = 0.5

    private let width: CGFloat
    private let threshold: CGFloat
    private let isRinging: Bool

    // How wide the label stands with room around it, which the action fades it in over.
    @State private var labelWidth = 0.0

    /// - Parameters:
    ///   - width: How far the timer has slid left, which the action fills, no further than the timer's own width.
    ///   - threshold: How far the timer slides before letting go takes it away.
    ///   - isRinging: Whether the timer rings, so swiping it away stops it rather than cancels it.
    init(
        width: CGFloat,
        threshold: CGFloat,
        isRinging: Bool
    ) {
        self.width = width
        self.threshold = threshold
        self.isRinging = isRinging
    }

    var body: some View {
        RunningTimerRow.shape
            .fill(.red)
            .overlay {
                label
            }
            .clipShape(RunningTimerRow.shape)
            .frame(width: max(0.0, width - Self.gap))
            .opacity(opacity)
            .animation(.runningTimers, value: isArmed)
            .accessibilityHidden(true)
    }

    // Always the same, cut off by the action's edges while it is narrow and fading in as it makes room for it.
    private var label: some View {
        RunningTimerRow.cancelTitle(isRinging: isRinging)
            .font(.callout.weight(.semibold))
            .foregroundStyle(.white)
            .fixedSize()
            .padding(.horizontal, SousSpacing.medium)
            .onGeometryChange(for: CGFloat.self, of: \.size.width) { measured in
                labelWidth = measured
            }
            .opacity(labelWidth > 0.0 ? min(1.0, max(0.0, (width - Self.gap) / labelWidth)) : 0.0)
    }

    private var isArmed: Bool {
        width >= threshold
    }

    private var opacity: Double {
        guard !isArmed else {
            return 1.0
        }

        return Self.unarmedOpacity * min(1.0, max(0.0, width / max(1.0, threshold)))
    }
}

#Preview("Running timer swipe reveal") {
    @Previewable @State var width = 120.0

    VStack(spacing: SousSpacing.large) {
        Slider(value: $width, in: 0.0...360.0)

        RunningTimerSwipeReveal(width: width, threshold: 180.0, isRinging: false)
            .frame(height: 64.0)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }
    .padding()
}
