@testable import KitchenFeature

/// A handler that counts the times the settings were asked for and restored.
@MainActor
final class KitchenFeatureHandlerStub: KitchenFeatureHandler {
    private(set) var settingsTapCount = 0
    private(set) var settingsRestoreCount = 0

    func kitchenFeatureDidTapSettings() {
        settingsTapCount += 1
    }

    func kitchenFeatureDidRestoreSettings() {
        settingsRestoreCount += 1
    }
}
