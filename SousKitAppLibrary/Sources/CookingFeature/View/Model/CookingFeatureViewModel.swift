import Observation
import SousKit

@Observable
@MainActor
final class CookingFeatureViewModel {
    let recipe: Recipe
    let title: String
    var completedStepNumbers: Set<Int> = []
    var isConfirmingExit = false
    var runningTimers: [RunningTimer] = []
    var startedTimerCount = 0
    var isTimerListOpen = false
    var timerConfirmingCancel: RunningTimer?
    var isAskingToAllowTimers = false

    nonisolated init(
        recipe: Recipe,
        title: String
    ) {
        self.recipe = recipe
        self.title = title
    }

    var canOpenTimerList: Bool {
        runningTimers.count > 1
    }

    func progress(ofStep number: Int) -> StepProgress {
        if completedStepNumbers.contains(number) {
            .done
        } else if (1..<number).allSatisfy(completedStepNumbers.contains) {
            .current
        } else {
            .upcoming
        }
    }

    func isRunning(_ id: RunningTimer.ID) -> Bool {
        runningTimers.contains(where: { $0.id == id })
    }
}
