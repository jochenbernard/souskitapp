import RecipeLibrary
import SousKit

extension StepTimer {
    /// A step's timer, or `nil` where it names no length of time.
    init?(_ timer: SousKit.Timer, stepNumber: Int) {
        guard let timerDuration = TimerDuration.duration(of: timer) else {
            return nil
        }

        self.init(
            stepNumber: stepNumber,
            text: timer.text,
            duration: timerDuration
        )
    }
}
