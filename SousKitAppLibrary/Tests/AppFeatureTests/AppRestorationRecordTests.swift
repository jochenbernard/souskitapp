@testable import AppFeature
import CookingFeature
import Foundation
@testable import KitchenFeature
import Testing

@Suite("App restoration record")
struct AppRestorationRecordTests {
    private let lastUse = Date(timeIntervalSinceReferenceDate: 0.0)

    private var withinLifetime: Date {
        lastUse.addingTimeInterval(AppRestorationRecord.lifetime - 1.0)
    }

    private var pastLifetime: Date {
        lastUse.addingTimeInterval(AppRestorationRecord.lifetime)
    }

    private func makeRecord(
        isTerminated: Bool = false,
        isSettling: Bool = false
    ) -> AppRestorationRecord {
        AppRestorationRecord(
            restoration: AppRestoration(
                kitchen: KitchenFeatureRestoration(recipeID: "crepes", cooking: CookingFeatureRestoration())
            ),
            lastUse: lastUse,
            isTerminated: isTerminated,
            isSettling: isSettling
        )
    }

    @Test("an app in use within the lifetime opens again")
    func withinLifetimeOpens() {
        #expect(makeRecord().isRestorable(at: withinLifetime, hasRunningTimers: false))
    }

    @Test("an app last in use a lifetime ago or more does not open")
    func pastLifetimeDoesNotOpen() {
        #expect(!makeRecord().isRestorable(at: pastLifetime, hasRunningTimers: false))
    }

    @Test("an app quit while it ran does not open")
    func terminatedDoesNotOpen() {
        #expect(!makeRecord(isTerminated: true).isRestorable(at: withinLifetime, hasRunningTimers: false))
    }

    @Test("a running timer opens an app quit while it ran, or past its lifetime")
    func runningTimerOpens() {
        #expect(makeRecord(isTerminated: true).isRestorable(at: withinLifetime, hasRunningTimers: true))
        #expect(makeRecord().isRestorable(at: pastLifetime, hasRunningTimers: true))
    }

    @Test("a restore that never settled does not open, even with a running timer")
    func unsettledRestoreDoesNotOpen() {
        #expect(!makeRecord(isSettling: true).isRestorable(at: withinLifetime, hasRunningTimers: true))
    }
}
