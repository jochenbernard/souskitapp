import Foundation

/// A timer as it was started, kept beside the alarm it sounds.
struct StartedTimer: Codable, Sendable {
    let cookingTimer: CookingTimer
    let endDate: Date
}
