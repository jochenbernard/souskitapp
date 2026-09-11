@testable import CookingFeature

/// Records what the cooking feature reports.
final class CookingFeatureHandlerSpy: CookingFeatureHandler {
    private(set) var exitCount = 0

    func cookingFeatureDidExit() {
        exitCount += 1
    }
}
