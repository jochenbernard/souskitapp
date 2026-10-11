import Observation

@Observable
@MainActor
final class AppFeatureViewModel {
    var screen: AppScreen
    var openSettings: OpenSettings?

    init(screen: AppScreen) {
        self.screen = screen
    }
}
