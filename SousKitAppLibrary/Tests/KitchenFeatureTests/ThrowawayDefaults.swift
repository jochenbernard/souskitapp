import Foundation
import Testing

/// A defaults suite of its own, removed once nothing holds it.
@MainActor
final class ThrowawayDefaults {
    let userDefaults: UserDefaults

    private let suiteName = "KitchenFeatureTests.\(UUID().uuidString)"

    init() throws {
        self.userDefaults = try #require(UserDefaults(suiteName: suiteName))
    }

    isolated deinit {
        userDefaults.removePersistentDomain(forName: suiteName)
    }
}
