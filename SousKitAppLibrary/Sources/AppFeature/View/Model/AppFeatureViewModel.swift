import Observation

@Observable
@MainActor
final class AppFeatureViewModel {
    var screen: AppScreen

    init(screen: AppScreen) {
        self.screen = screen
    }
}
