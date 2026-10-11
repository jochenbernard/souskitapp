import Foundation

/// What the app has open, kept across launches so a cold start opens the app as it was left.
///
/// Written on every change rather than when the app leaves the foreground, so a crash loses nothing.
@MainActor
struct AppRestorationStore {
    private static let key = "AppRestorationStore.record"

    private let userDefaults: UserDefaults

    /// Creates a store.
    ///
    /// - Parameter userDefaults: Where what the app has open is kept.
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    /// Forgets what the app has open, so the next cold start opens on the recipe list.
    func clear() {
        userDefaults.removeObject(forKey: Self.key)
    }

    /// What the app had open, or `nil` where nothing was.
    func restoration() -> AppRestoration? {
        record()?.restoration
    }

    func record() -> AppRestorationRecord? {
        guard let data = userDefaults.data(forKey: Self.key) else {
            return nil
        }

        return try? JSONDecoder().decode(AppRestorationRecord.self, from: data)
    }

    /// Changes what the app has open, in use now, and forgets it all once nothing is open.
    ///
    /// - Parameter change: The change, made to what is kept or to nothing open.
    func update(_ change: (inout AppRestoration) -> Void) {
        let previous = record()
        var restoration = previous?.restoration ?? AppRestoration()
        change(&restoration)

        guard !restoration.isEmpty else {
            clear()
            return
        }

        // A change made while a cold start settles keeps it unsettled, so a crash in it still counts.
        write(
            AppRestorationRecord(
                restoration: restoration,
                lastUse: .now,
                isSettling: previous?.isSettling ?? false
            )
        )
    }

    /// Records that the app is in use now.
    func recordUse() {
        updateRecord({ $0.lastUse = .now })
    }

    /// Records that the app is being quit.
    func recordTermination() {
        updateRecord({ $0.isTerminated = true })
    }

    /// Records that a cold start is opening what the app had open, in use now.
    func beginSettling() {
        updateRecord { record in
            record.isSettling = true
            record.lastUse = .now
        }
    }

    /// Records that the cold start opening what the app had open settled.
    func finishSettling() {
        updateRecord({ $0.isSettling = false })
    }

    private func updateRecord(_ change: (inout AppRestorationRecord) -> Void) {
        guard var record = record() else {
            return
        }

        change(&record)
        write(record)
    }

    private func write(_ record: AppRestorationRecord) {
        userDefaults.set(try? JSONEncoder().encode(record), forKey: Self.key)
    }
}
