import DesignSystem
import SwiftUI

/// A running timer's fill, growing as its time runs out.
///
/// Reads whether its timer shows what it is here rather than in the row, so a frame of the timers opening updates the
/// fill alone.
struct RunningTimerProgress: View {
    // How many steps the fill grows in, about a pixel each across the widest timer.
    private static let steps = 1_200.0

    private let timer: RunningTimer
    private let contentFade: RunningTimersMotionFade

    /// - Parameter contentFade: How the timer shows what it is, out of sight of which the fill stops.
    init(timer: RunningTimer, contentFade: RunningTimersMotionFade) {
        self.timer = timer
        self.contentFade = contentFade
    }

    // Redrawn from the clock about as often as the fill grows by a pixel, so it keeps time with the countdown beside
    // it. Scaled rather than sized, so a redraw lays nothing out.
    var body: some View {
        TimelineView(.animation(minimumInterval: interval, paused: isPaused)) { context in
            let fraction = timer.fractionElapsed(at: context.date)

            Rectangle()
                .fill(.accent.opacity(timer.isRinging ? 0.32 : 0.2))
                .scaleEffect(
                    x: fraction,
                    y: 1.0,
                    anchor: .leading
                )
                // A fill paused out of sight catches up at once, not on the spring that brings its timer forward.
                .animation(nil, value: fraction)
        }
    }

    private var interval: Double {
        timer.stepTimer.seconds / Self.steps
    }

    private var isPaused: Bool {
        timer.isRinging || contentFade.isHidden
    }
}

#Preview("Running timer progress") {
    RunningTimerProgress(timer: RunningTimersPreview.timers()[1], contentFade: .disabled)
        .frame(height: 64.0)
        .padding()
}
