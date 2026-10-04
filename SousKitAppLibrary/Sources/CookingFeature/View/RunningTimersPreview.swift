import Foundation
import SousKit

/// The timers the previews of the panel run.
enum RunningTimersPreview {
    /// Three timers, soonest first, the first of them ringing.
    ///
    /// - Parameter date: When the ringing timer was over.
    /// - Returns: The timers.
    static func timers(endingAround date: Date = .now) -> [RunningTimer] {
        [
            RunningTimer(
                id: UUID(),
                stepTimer: StepTimer(
                    stepNumber: 2,
                    text: "5-6 min",
                    duration: .seconds(300)
                ),
                endDate: date,
                isRinging: true
            ),
            RunningTimer(
                id: UUID(),
                stepTimer: StepTimer(
                    stepNumber: 3,
                    text: "15 min",
                    duration: .seconds(900)
                ),
                endDate: date.addingTimeInterval(260.0),
                isRinging: false
            ),
            RunningTimer(
                id: UUID(),
                stepTimer: StepTimer(
                    stepNumber: 1,
                    text: "30 min",
                    duration: .seconds(1_800)
                ),
                endDate: date.addingTimeInterval(1_500.0),
                isRinging: false
            )
        ]
    }

    /// A view model with the three timers running.
    ///
    /// - Parameters:
    ///   - isTimerListOpen: Whether the list of them is open.
    ///   - recipe: The recipe being cooked, a one-step one unless given.
    ///   - title: The recipe's title.
    /// - Returns: The view model.
    @MainActor
    static func viewModel(
        isTimerListOpen: Bool,
        recipe: Recipe = SousParser().parseRecipe("Whisk it.").value,
        title: String = "Vinaigrette"
    ) -> CookingFeatureViewModel {
        let viewModel = CookingFeatureViewModel(
            recipe: recipe,
            title: title
        )
        viewModel.runningTimers = timers()
        viewModel.isTimerListOpen = isTimerListOpen
        return viewModel
    }
}
