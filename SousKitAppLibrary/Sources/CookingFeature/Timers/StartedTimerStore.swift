import Foundation

/// The timers started, by the alarm each sounds, kept across launches since an alarm outlives the app.
struct StartedTimerStore: Sendable {
    private static let key = "startedTimers"

    nonisolated(unsafe) private let userDefaults: UserDefaults

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
    func removeFinished(keeping ids: Set<UUID>, now: Date) {
        save(startedTimers().filter({ ids.contains($0.key) || $0.value.endDate > now }))
    }

    private func save(_ startedTimers: [UUID: StartedTimer]) {
        userDefaults.set(try? JSONEncoder().encode(startedTimers), forKey: Self.key)
    }
}
