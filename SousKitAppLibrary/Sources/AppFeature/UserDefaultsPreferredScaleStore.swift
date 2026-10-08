import Foundation
import RecipeLibrary

/// The scale recipes open on, remembered in the user's defaults.
@MainActor
struct UserDefaultsPreferredScaleStore: PreferredScaleStore {
    private static let key = "UserDefaultsPreferredScaleStore.preferredScale"

    private let userDefaults: UserDefaults

    var preferredScale: PreferredScale {
        guard
            let data = userDefaults.data(forKey: Self.key),
            let remembered = try? JSONDecoder().decode(PreferredScale.self, from: data)
        else {
            return .asWritten
        }

        return remembered
    }

    /// Creates a store.
    ///
    /// - Parameter userDefaults: Where the scale is remembered.
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func remember(_ preferredScale: PreferredScale) {
        userDefaults.set(try? JSONEncoder().encode(preferredScale), forKey: Self.key)
    }

    /// Forgets the scale, leaving recipes to open as written.
    func clear() {
        userDefaults.removeObject(forKey: Self.key)
    }
}
