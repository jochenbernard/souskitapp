import CookingFeature
import Foundation
@testable import KitchenFeature
import Testing

@Suite("Kitchen restoration record")
struct KitchenRestorationRecordTests {
    private let lastUse = Date(timeIntervalSinceReferenceDate: 0.0)

    private var withinLifetime: Date {
        lastUse.addingTimeInterval(KitchenRestorationRecord.lifetime - 1.0)
    }

    private var pastLifetime: Date {
        lastUse.addingTimeInterval(KitchenRestorationRecord.lifetime)
    }

    private func makeRecord(
        isTerminated: Bool = false,
        isRestoring: Bool = false
    ) -> KitchenRestorationRecord {
        KitchenRestorationRecord(
            restoration: KitchenRestoration(recipeID: "crepes", cooking: CookingFeatureRestoration()),
            lastUse: lastUse,
            isTerminated: isTerminated,
            isRestoring: isRestoring
        )
    }

    @Test("a kitchen in use within the lifetime opens again")
    func withinLifetimeOpens() {
        #expect(makeRecord().isRestorable(at: withinLifetime, hasRunningTimers: false))
    }

    @Test("a kitchen last in use a lifetime ago or more does not open")
    func pastLifetimeDoesNotOpen() {
        #expect(!makeRecord().isRestorable(at: pastLifetime, hasRunningTimers: false))
    }

    @Test("a kitchen quit while it ran does not open")
    func terminatedDoesNotOpen() {
        #expect(!makeRecord(isTerminated: true).isRestorable(at: withinLifetime, hasRunningTimers: false))
    }

    @Test("a running timer opens a kitchen quit while it ran, or past its lifetime")
    func runningTimerOpens() {
        #expect(makeRecord(isTerminated: true).isRestorable(at: withinLifetime, hasRunningTimers: true))
        #expect(makeRecord().isRestorable(at: pastLifetime, hasRunningTimers: true))
    }

    @Test("a restore that never settled does not open, even with a running timer")
    func unsettledRestoreDoesNotOpen() {
        #expect(!makeRecord(isRestoring: true).isRestorable(at: withinLifetime, hasRunningTimers: true))
    }
}
