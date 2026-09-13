@testable import KitchenFeature

/// A handler that counts the resets reported to it.
@MainActor
final class KitchenFeatureHandlerStub: KitchenFeatureHandler {
    private(set) var resetCount = 0

    func kitchenFeatureDidConfirmReset() {
        resetCount += 1
    }
}
