import AlarmKit
import DesignSystem
import SwiftUI

/// Timers sounded as system alarms, which ring even while the app is closed.
public struct AlarmTimerScheduler: TimerScheduler {
    private let startedTimerStore: StartedTimerStore

    /// Creates a scheduler.
    public init() {
        self.startedTimerStore = StartedTimerStore()
    }

    public func runningTimers() -> AsyncStream<[RunningTimer]> {
        AsyncStream { continuation in
            // On the main actor, where starting and cancelling also write the started timers, so no write is lost.
            let task = Task { @MainActor in
                continuation.yield(runningTimers(of: (try? AlarmManager.shared.alarms) ?? []))

                for await alarms in AlarmManager.shared.alarmUpdates {
                    continuation.yield(runningTimers(of: alarms))
                }

                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    public func start(_ timer: StepTimer) async throws {
        let manager = AlarmManager.shared

        if manager.authorizationState == .notDetermined {
            _ = try await manager.requestAuthorization()
        }

        guard manager.authorizationState == .authorized else {
            throw TimerSchedulerError.notAuthorized
        }

        let id = UUID()

        // Kept before scheduling, so the first update carrying the alarm finds it.
        startedTimerStore.add(StartedTimer(stepTimer: timer, endDate: .now.addingTimeInterval(timer.seconds)), id: id)

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
        if timer.isRinging {
            try AlarmManager.shared.stop(id: timer.id)
        } else {
            try AlarmManager.shared.cancel(id: timer.id)
        }

        startedTimerStore.remove(id: timer.id)
    }

    private func runningTimers(of alarms: [Alarm]) -> [RunningTimer] {
        let startedTimers = startedTimerStore.removeFinished(keeping: Set(alarms.map(\.id)))

        return alarms
            .compactMap { alarm in
                startedTimers[alarm.id].map { startedTimer in
                    RunningTimer(
                        id: alarm.id,
                        stepTimer: startedTimer.stepTimer,
                        endDate: startedTimer.endDate,
                        isRinging: alarm.state == .alerting
                    )
                }
            }
            .sorted(by: { $0.endDate < $1.endDate })
    }

    private func attributes(of timer: StepTimer) -> AlarmAttributes<CookingTimerMetadata> {
        // The system reads the title out of process, so it names the bundle by its location.
        let title = LocalizedStringResource(
            "\(timer.text) for step \(timer.stepNumber)",
            bundle: .atURL(Bundle.module.bundleURL)
        )

        return AlarmAttributes(
            presentation: AlarmPresentation(
                alert: AlarmPresentation.Alert(title: title),
                countdown: AlarmPresentation.Countdown(title: title)
            ),
            tintColor: .accent
        )
    }
}
