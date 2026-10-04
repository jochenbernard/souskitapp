import Observation
import SousKit

@Observable
@MainActor
final class CookingFeatureViewModel {
    let recipe: Recipe
    let title: String
    private let stepNumbers: Range<Int>
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
        self.stepNumbers = 1..<(recipe.groups.map(\.steps.count).reduce(0, +) + 1)
    }

    var canOpenTimerList: Bool {
        runningTimers.count > 1
    }

    private var currentStepNumber: Int? {
        stepNumbers.first(where: { !completedStepNumbers.contains($0) })
    }

    func progress(ofStep number: Int) -> StepProgress {
        if completedStepNumbers.contains(number) {
            .done
        } else if number == currentStepNumber {
            .current
        } else {
            .upcoming
        }
    }

    func isRunning(_ id: RunningTimer.ID) -> Bool {
        runningTimers.contains(where: { $0.id == id })
    }
}
