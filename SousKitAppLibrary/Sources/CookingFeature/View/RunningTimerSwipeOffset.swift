import DesignSystem
import SwiftUI

/// Slides a running timer sideways by its swipe, and records where each frame draws it, so a finger catching it on a
/// spring takes it up there.
private struct RunningTimerSwipeOffset: GeometryEffect {
    var animatableData: CGFloat

    private let id: RunningTimer.ID
    private let metrics: RunningTimersLayoutMetrics

    nonisolated init(
        offset: CGFloat,
        id: RunningTimer.ID,
        metrics: RunningTimersLayoutMetrics
    ) {
        self.animatableData = offset
        self.id = id
        self.metrics = metrics
    }

    func effectValue(size _: CGSize) -> ProjectionTransform {
        metrics.updateSwipeOffset(animatableData, of: id)
        return ProjectionTransform(CGAffineTransform(translationX: animatableData, y: 0.0))
    }
}

extension View {
    /// Slides the running timer sideways by its swipe, and records where each frame draws it.
    ///
    /// - Parameters:
    ///   - offset: How far the timer is swiped, left for negative values.
    ///   - id: The timer.
    ///   - metrics: Where to record how far the timer was drawn swiped.
    /// - Returns: The timer, slid sideways.
    func runningTimerSwipeOffset(
        _ offset: CGFloat,
        id: RunningTimer.ID,
        metrics: RunningTimersLayoutMetrics
    ) -> some View {
        modifier(
            RunningTimerSwipeOffset(
                offset: offset,
                id: id,
                metrics: metrics
            )
        )
    }
}

#Preview("Running timer swipe offset") {
    @Previewable @State var offset = -120.0

    let timer = RunningTimersPreview.timers()[1]

    VStack(spacing: SousSpacing.large) {
        Slider(value: $offset, in: -360.0...60.0)

        RunningTimerRow(
            presenter: CookingFeaturePresenterStub(),
            timer: timer,
            isConfirmingCancel: false
        )
        .runningTimerSwipeOffset(
            offset,
            id: timer.id,
            metrics: RunningTimersLayoutMetrics()
        )
    }
    .padding()
}
