import Foundation

/// What the kitchen has open, with how the app last ran, which decides whether a cold start opens it again.
struct KitchenRestorationRecord: Codable {
    /// How long after the kitchen was last in use a cold start still opens it as it was left.
    static let lifetime: TimeInterval = 12.0 * 60.0 * 60.0

    /// What the kitchen has open.
    var restoration: KitchenRestoration

    /// When the kitchen was last in use.
    var lastUse: Date

    /// Whether the app was quit while it ran, rather than crashing or being stopped by the system.
    var isTerminated = false

    /// Whether a cold start is opening the restoration and has not settled yet.
    var isSettling = false

    /// Whether a cold start opens the restoration again.
    ///
    /// - Parameters:
    ///   - date: When the cold start happens.
    ///   - hasRunningTimers: Whether a timer is counting down or ringing, asked only where it decides.
    /// - Returns: Whether the restoration opens.
    func isRestorable(at date: Date, hasRunningTimers: @autoclosure @MainActor () async -> Bool) async -> Bool {
        // A restoration that never settled took the app down with it, and would again.
        guard !isSettling else {
            return false
        }

        guard isTerminated || date.timeIntervalSince(lastUse) >= Self.lifetime else {
            return true
        }

        // A timer outlives the app, so cooking comes back to show it and cancel it, however the app ended.
        return await hasRunningTimers()
    }
}
