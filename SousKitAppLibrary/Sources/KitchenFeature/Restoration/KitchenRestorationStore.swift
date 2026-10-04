import Foundation

/// What the kitchen has open, kept across launches so a cold start opens the kitchen as it was left.
///
/// Written on every change rather than when the app leaves the foreground, so a crash or a force quit loses nothing.
@MainActor
public struct KitchenRestorationStore {
    private static let key = "KitchenRestorationStore.restoration"

    private let userDefaults: UserDefaults

    /// Creates a store.
    ///
    /// - Parameter userDefaults: Where what the kitchen has open is kept.
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    /// Forgets what the kitchen has open, so the next kitchen opens on its recipe list.
    public func clear() {
        userDefaults.removeObject(forKey: Self.key)
    }

    /// What the kitchen had open, or `nil` where it stood on its recipe list.
    func restoration() -> KitchenRestoration? {
        guard let data = userDefaults.data(forKey: Self.key) else {
            return nil
        }

        return try? JSONDecoder().decode(KitchenRestoration.self, from: data)
    }

    /// Records what the kitchen has open.
    ///
    /// - Parameter restoration: What the kitchen has open.
    func save(_ restoration: KitchenRestoration) {
        guard let data = try? JSONEncoder().encode(restoration) else {
            clear()
            return
        }

        userDefaults.set(data, forKey: Self.key)
    }
}
