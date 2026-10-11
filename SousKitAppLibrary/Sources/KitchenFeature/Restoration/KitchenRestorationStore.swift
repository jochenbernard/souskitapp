import Foundation

/// What the kitchen has open, kept across launches so a cold start opens the kitchen as it was left.
///
/// Written on every change rather than when the app leaves the foreground, so a crash loses nothing.
@MainActor
public struct KitchenRestorationStore {
    private static let key = "KitchenRestorationStore.record"

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

    /// Records that the settings are open over the recipe list, in use now.
    public func saveSettings() {
        save(KitchenRestoration(recipeID: nil, isShowingSettings: true))
    }

    /// What the kitchen had open, or `nil` where it stood on its recipe list with nothing over it.
    func restoration() -> KitchenRestoration? {
        record()?.restoration
    }

    func record() -> KitchenRestorationRecord? {
        guard let data = userDefaults.data(forKey: Self.key) else {
            return nil
        }

        return try? JSONDecoder().decode(KitchenRestorationRecord.self, from: data)
    }

    /// Records what the kitchen has open, in use now.
    ///
    /// - Parameter restoration: What the kitchen has open.
    func save(_ restoration: KitchenRestoration) {
        write(restoration, over: record())
    }

    /// Changes what the kitchen has open for a recipe, in use now, or leaves the store as it is where another is open.
    ///
    /// - Parameters:
    ///   - recipeID: The id of the recipe the change is for.
    ///   - change: The change.
    func update(recipeID: String, _ change: (inout KitchenRestoration) -> Void) {
        guard
            var record = record(),
            record.restoration.recipeID == recipeID
        else {
            return
        }

        change(&record.restoration)
        write(record.restoration, over: record)
    }

    /// Records that the kitchen is in use now.
    func recordUse() {
        update({ $0.lastUse = .now })
    }

    /// Records that the app is being quit.
    func recordTermination() {
        update({ $0.isTerminated = true })
    }

    /// Records that a cold start is opening what the kitchen had open, in use now.
    func beginSettling() {
        update { record in
            record.isSettling = true
            record.lastUse = .now
        }
    }

    /// Records that the cold start opening what the kitchen had open settled.
    func finishSettling() {
        update({ $0.isSettling = false })
    }

    private func update(_ change: (inout KitchenRestorationRecord) -> Void) {
        guard var record = record() else {
            return
        }

        change(&record)
        write(record)
    }

    private func write(_ restoration: KitchenRestoration, over previous: KitchenRestorationRecord?) {
        // A change made while a cold start settles keeps it unsettled, so a crash in it still counts.
        write(
            KitchenRestorationRecord(
                restoration: restoration,
                lastUse: .now,
                isSettling: previous?.isSettling ?? false
            )
        )
    }

    private func write(_ record: KitchenRestorationRecord) {
        userDefaults.set(try? JSONEncoder().encode(record), forKey: Self.key)
    }
}
