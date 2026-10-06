import SwiftUI

extension Animation {
    /// How long the running timers take to move, which a timer swiped away is given to fly off.
    static let runningTimersDuration = 0.4
    private static let runningTimersBounce = 0.2

    /// How long a timer takes to swoop from the front of the stack to its place behind the others, slower than the
    /// timers' other movements so it can be followed.
    static let runningTimerSwoopDuration = 0.6

    /// How the running timers move, whatever moves them: a timer coming or going, the stack opening or folding back,
    /// or the list settling after a swipe. It overshoots a little.
    static let runningTimers = Animation.spring(duration: runningTimersDuration, bounce: runningTimersBounce)

    /// How long the running timers take to come to rest once moved, overshoot included.
    static let runningTimersSettlingDuration = Spring(
        duration: runningTimersDuration,
        bounce: runningTimersBounce
    ).settlingDuration

    /// How a timer swoops from the front of the stack to its place behind the others: the timers' spring, slower.
    static let runningTimerSwoop = Animation.spring(duration: runningTimerSwoopDuration, bounce: runningTimersBounce)

    /// The same movement starting at a speed, so what a swipe let go of carries on at the finger's pace.
    ///
    /// - Parameter initialVelocity: The speed to start at, as the share of the distance covered in a second.
    /// - Returns: The animation.
    static func runningTimers(initialVelocity: Double) -> Animation {
        .interpolatingSpring(
            duration: runningTimersDuration,
            bounce: runningTimersBounce,
            initialVelocity: initialVelocity
        )
    }
}
