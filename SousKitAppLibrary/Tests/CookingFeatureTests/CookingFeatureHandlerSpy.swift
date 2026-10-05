@testable import CookingFeature

/// Records what the cooking feature reports.
final class CookingFeatureHandlerSpy: CookingFeatureHandler {
    private(set) var exitCount = 0
    private(set) var restorations: [CookingFeatureRestoration] = []

    func cookingFeatureDidExit() {
        exitCount += 1
    }

    func cookingFeatureDidChangeRestoration(_ restoration: CookingFeatureRestoration) {
        restorations.append(restoration)
    }
}
