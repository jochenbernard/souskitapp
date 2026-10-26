import Foundation

/// A stand-in for the scheduler in scratch builds only: timers kept in memory, needing no AlarmKit permission.
///
/// A timer is marked as ringing once its time is over, without any sound, and nothing outlives the process.
public struct AlarmTimerScheduler: TimerScheduler {
    @MainActor
    private final class Store {
        static let shared = Store()

        var timers: [RunningTimer] = []
        var startedLate = false
        var continuations: [UUID: AsyncStream<[RunningTimer]>.Continuation] = [:]

        // Scratch only: SOUS_STANDIN_TIMERS=n has n timers running from the start, as after a relaunch.
        init() {
            let count = Int(ProcessInfo.processInfo.environment["SOUS_STANDIN_TIMERS"] ?? "") ?? 0

            for index in 0..<count {
                let timer = CookingTimer.custom(.seconds(1_800 + 300 * index))
                timers.append(
                    RunningTimer(
                        id: UUID(),
                        cookingTimer: timer,
                        endDate: Date.now.addingTimeInterval(timer.seconds),
                        isRinging: false
                    )
                )
            }
        }

        // Scratch only: SOUS_STANDIN_LATE=s starts a two hour timer s seconds after the launch, behind the others.
        func startLate() {
            guard !startedLate, let delay = Double(ProcessInfo.processInfo.environment["SOUS_STANDIN_LATE"] ?? "") else {
                return
            }

            startedLate = true

            Task { @MainActor in
                try? await Task.sleep(for: .seconds(delay))
                let timer = CookingTimer.custom(.seconds(7_200))
                timers.append(
                    RunningTimer(
                        id: UUID(),
                        cookingTimer: timer,
                        endDate: Date.now.addingTimeInterval(timer.seconds),
                        isRinging: false
                    )
                )
                publish()
            }
        }

        func publish() {
            timers.sort(by: { $0.endDate < $1.endDate })

            for continuation in continuations.values {
                continuation.yield(timers)
            }
        }
    }

    @MainActor
    public init() {
        Store.shared.startLate()
    }

    public func currentRunningTimers() -> [RunningTimer] {
        Store.shared.timers
    }

    public func runningTimers() -> AsyncStream<[RunningTimer]> {
        let key = UUID()
        let (stream, continuation) = AsyncStream.makeStream(of: [RunningTimer].self)
        Store.shared.continuations[key] = continuation
        continuation.yield(Store.shared.timers)
        continuation.onTermination = { _ in
            Task { @MainActor in
                Store.shared.continuations[key] = nil
            }
        }
        return stream
    }

    public func start(_ timer: CookingTimer) async throws {
        let id = UUID()
        let endDate = Date.now.addingTimeInterval(timer.seconds)
        Store.shared.timers.append(
            RunningTimer(
                id: id,
                cookingTimer: timer,
                endDate: endDate,
                isRinging: false
            )
        )
        Store.shared.publish()

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(timer.seconds))

            if let index = Store.shared.timers.firstIndex(where: { $0.id == id }) {
                Store.shared.timers[index] = RunningTimer(
                    id: id,
                    cookingTimer: timer,
                    endDate: endDate,
                    isRinging: true
                )
                Store.shared.publish()
            }
        }
    }

    public func cancel(_ timer: RunningTimer) throws {
        Store.shared.timers.removeAll(where: { $0.id == timer.id })
        Store.shared.publish()
    }

    public func cancelAll() {
        Store.shared.timers.removeAll()
        Store.shared.publish()
    }
}
