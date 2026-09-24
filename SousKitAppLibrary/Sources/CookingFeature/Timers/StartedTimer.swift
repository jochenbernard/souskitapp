import Foundation

/// A timer as it was started, kept beside the alarm it sounds.
struct StartedTimer: Codable, Sendable {
    let stepTimer: StepTimer
    let endDate: Date
}
