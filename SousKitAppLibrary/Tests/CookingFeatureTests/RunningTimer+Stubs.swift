@testable import CookingFeature
import Foundation

extension RunningTimer {
    /// The stubbed step timer, counting down or ringing.
    static func stubbed(isRinging: Bool = false) -> Self {
        Self(
            id: UUID(),
            cookingTimer: .step(.stubbed()),
            endDate: .now.addingTimeInterval(900.0),
            isRinging: isRinging
        )
    }
}
