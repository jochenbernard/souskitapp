@testable import CookingFeature
import Foundation
import Testing

@Suite("Started timer store")
@MainActor
final class StartedTimerStoreTests {
    private let suiteName = "StartedTimerStoreTests-\(UUID().uuidString)"
    private let userDefaults: UserDefaults

    init() throws {
        self.userDefaults = try #require(UserDefaults(suiteName: suiteName))
    }

    isolated deinit {
        userDefaults.removePersistentDomain(forName: suiteName)
    }

    @Test("a step's timer and a custom one are both there after a cold start")
    func timersOutliveTheStore() {
        let stepID = UUID()
        let customID = UUID()
        let endDate = Date.now.addingTimeInterval(900.0)
        let stepTimer = StartedTimer(cookingTimer: .step(.stubbed()), endDate: endDate)
        let customTimer = StartedTimer(cookingTimer: .custom(.seconds(90)), endDate: endDate)

        let store = StartedTimerStore(userDefaults: userDefaults)
        store.add(stepTimer, id: stepID)
        store.add(customTimer, id: customID)

        let startedTimers = StartedTimerStore(userDefaults: userDefaults).startedTimers()

        #expect(startedTimers[stepID]?.cookingTimer == stepTimer.cookingTimer)
        #expect(startedTimers[customID]?.cookingTimer == customTimer.cookingTimer)
        #expect(startedTimers.count == 2)
    }

    @Test("clearing forgets every timer, leaving nothing kept")
    func clearing() {
        let store = StartedTimerStore(userDefaults: userDefaults)
        store.add(StartedTimer(cookingTimer: .custom(.seconds(90)), endDate: .now.addingTimeInterval(90.0)), id: UUID())

        store.clear()

        #expect(StartedTimerStore(userDefaults: userDefaults).startedTimers().isEmpty)
        #expect(userDefaults.persistentDomain(forName: suiteName)?.isEmpty ?? true)
    }
}
