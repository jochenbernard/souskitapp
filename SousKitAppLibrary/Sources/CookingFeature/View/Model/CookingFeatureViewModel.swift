import Observation
import SousKit

@Observable
@MainActor
final class CookingFeatureViewModel {
    let recipe: Recipe
    var isConfirmingExit = false
    var runningTimers: [RunningTimer] = []
    var startedTimerCount = 0
    var isTimerListOpen = false
    var timerConfirmingCancel: RunningTimer?
    var isAskingToAllowTimers = false

    nonisolated init(recipe: Recipe) {
        self.recipe = recipe
    }
}
