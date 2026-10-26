import Foundation

/// The timers started, by the alarm each sounds, kept across launches since an alarm outlives the app.
@MainActor
struct StartedTimerStore {
    private static let key = "StartedTimerStore.startedTimers"

    private let userDefaults: UserDefaults

    /// Creates a store.
    ///
    /// - Parameter userDefaults: Where the timers are kept.
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func startedTimers() -> [UUID: StartedTimer] {
        guard
            let data = userDefaults.data(forKey: Self.key),
            let startedTimers = try? JSONDecoder().decode([UUID: StartedTimer].self, from: data)
        else {
            return [:]
        }

        return startedTimers
    }

    func add(_ startedTimer: StartedTimer, id: UUID) {
        var startedTimers = startedTimers()
        startedTimers[id] = startedTimer
        save(startedTimers)
    }

    func remove(id: UUID) {
        var startedTimers = startedTimers()
        startedTimers[id] = nil
        save(startedTimers)
    }

    /// Forgets the timers over whose alarm is gone.
    ///
    /// - Returns: The timers kept.
    func removeFinished(keeping ids: Set<UUID>) -> [UUID: StartedTimer] {
        let startedTimers = startedTimers()
        let kept = startedTimers.filter({ ids.contains($0.key) || $0.value.endDate > .now })

        if kept.count != startedTimers.count {
            save(kept)
        }

        return kept
    }

    /// Forgets every timer.
    func clear() {
        userDefaults.removeObject(forKey: Self.key)
    }

    private func save(_ startedTimers: [UUID: StartedTimer]) {
        userDefaults.set(try? JSONEncoder().encode(startedTimers), forKey: Self.key)
    }
}
