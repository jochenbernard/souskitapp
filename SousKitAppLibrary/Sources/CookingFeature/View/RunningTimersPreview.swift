import Foundation
import SousKit

/// The timers the previews of the panel run, on a view model of a one-step recipe.
enum RunningTimersPreview {
    /// A view model with three timers running, one of them ringing.
    ///
    /// - Parameter isTimerListOpen: Whether the list of them is open.
    /// - Returns: The view model.
    @MainActor
    static func viewModel(isTimerListOpen: Bool) -> CookingFeatureViewModel {
        let date = Date.now
        let viewModel = CookingFeatureViewModel(recipe: SousParser().parseRecipe("Whisk it.").value)
        viewModel.runningTimers = [
            RunningTimer(
                id: UUID(),
                stepTimer: StepTimer(stepNumber: 2, text: "5-6 min", duration: .seconds(300)),
                endDate: date,
                isRinging: true
            ),
            RunningTimer(
                id: UUID(),
                stepTimer: StepTimer(stepNumber: 3, text: "15 min", duration: .seconds(900)),
                endDate: date.addingTimeInterval(260),
                isRinging: false
            ),
            RunningTimer(
                id: UUID(),
                stepTimer: StepTimer(stepNumber: 1, text: "30 min", duration: .seconds(1_800)),
                endDate: date.addingTimeInterval(1_500),
                isRinging: false
            )
        ]
        viewModel.isTimerListOpen = isTimerListOpen
        return viewModel
    }
}
