import AlarmKit
import DesignSystem

/// Timers sounded as system alarms, which ring even while the app is closed.
public struct AlarmTimerScheduler: TimerScheduler {
    private let startedTimerStore: StartedTimerStore

    /// Creates a scheduler, cancelling every timer no record is kept of.
    @MainActor
    public init() {
        self.startedTimerStore = StartedTimerStore()
        cancelUntrackedTimers()
    }

    public func currentRunningTimers() -> [RunningTimer] {
        runningTimers(of: (try? AlarmManager.shared.alarms) ?? [])
    }

    public func runningTimers() -> AsyncStream<[RunningTimer]> {
        AsyncStream { continuation in
            let task = Task { @MainActor in
                continuation.yield(currentRunningTimers())

                for await alarms in AlarmManager.shared.alarmUpdates {
                    continuation.yield(runningTimers(of: alarms))
                }

                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    public func start(_ timer: CookingTimer) async throws {
        let manager = AlarmManager.shared

        if manager.authorizationState == .notDetermined {
            _ = try await manager.requestAuthorization()
        }

        guard manager.authorizationState == .authorized else {
            throw TimerSchedulerError.notAuthorized
        }

        let id = UUID()

        // Kept before scheduling, so the first update carrying the alarm finds it.
        startedTimerStore.add(
            StartedTimer(cookingTimer: timer, endDate: .now.addingTimeInterval(timer.seconds)),
            id: id
        )

        do {
            _ = try await manager.schedule(
                id: id,
                configuration: .timer(duration: timer.seconds, attributes: attributes(of: timer))
            )
        } catch {
            startedTimerStore.remove(id: id)
            throw error
        }
    }

    public func cancel(_ timer: RunningTimer) throws {
        // The alarm itself, since the timer may have started ringing after it was handed over.
        let alarm = try AlarmManager.shared.alarms.first(where: { $0.id == timer.id })

        try silence(id: timer.id, isRinging: alarm?.state == .alerting)
        startedTimerStore.remove(id: timer.id)
    }

    // An alarm whose record is gone still rings, with no screen showing it or able to stop it.
    @MainActor
    private func cancelUntrackedTimers() {
        let alarms = (try? AlarmManager.shared.alarms) ?? []
        let startedTimers = startedTimerStore.startedTimers()

        for alarm in alarms where startedTimers[alarm.id] == nil {
            try? silence(id: alarm.id, isRinging: alarm.state == .alerting)
        }
    }

    @MainActor
    private func silence(id: UUID, isRinging: Bool) throws {
        if isRinging {
            try AlarmManager.shared.stop(id: id)
        } else {
            try AlarmManager.shared.cancel(id: id)
        }
    }

    @MainActor
    private func runningTimers(of alarms: [Alarm]) -> [RunningTimer] {
        let startedTimers = startedTimerStore.removeFinished(keeping: Set(alarms.map(\.id)))

        return alarms
            .compactMap { alarm in
                startedTimers[alarm.id].map { startedTimer in
                    RunningTimer(
                        id: alarm.id,
                        cookingTimer: startedTimer.cookingTimer,
                        endDate: startedTimer.endDate,
                        isRinging: alarm.state == .alerting
                    )
                }
            }
            .sorted(by: { $0.endDate < $1.endDate })
    }

    private func attributes(of timer: CookingTimer) -> AlarmAttributes<CookingTimerMetadata> {
        // The system reads the title out of process, so it names the bundle by its location.
        let bundle = LocalizedStringResource.BundleDescription.atURL(Bundle.module.bundleURL)
        let title = switch timer {
        case .step(let stepTimer):
            LocalizedStringResource("\(stepTimer.text) for step \(stepTimer.stepNumber)", bundle: bundle)

        case .custom:
            LocalizedStringResource("\(timer.text) custom timer", bundle: bundle)
        }

        return AlarmAttributes(
            presentation: AlarmPresentation(
                alert: AlarmPresentation.Alert(title: title),
                countdown: AlarmPresentation.Countdown(title: title)
            ),
            tintColor: .accent
        )
    }
}
