import SwiftUI

/// What the number a cook enters for a new timer counts.
enum TimerUnit: CaseIterable, Hashable, Codable, Sendable {
    case seconds
    case minutes
    case hours

    /// What names the unit among the others.
    var name: Text {
        switch self {
        case .seconds: Text("Seconds", bundle: .module)
        case .minutes: Text("Minutes", bundle: .module)
        case .hours: Text("Hours", bundle: .module)
        }
    }

    /// How many seconds one of the unit lasts.
    var seconds: Double {
        switch self {
        case .seconds: 1.0
        case .minutes: 60.0
        case .hours: 3_600.0
        }
    }
}
