import SwiftUI

/// The timing a Sous button press travels on.
enum ButtonPress {
    /// How far a press shrinks a control that scales.
    static let scale = 0.97

    /// How hard the release taps, against a press at full strength.
    static let releaseIntensity = 0.4

    /// How long a control takes to reach its pressed size.
    static let pressDuration = 0.1

    /// How long it takes to come back.
    static let releaseDuration = 0.25

    /// How far the return overshoots. The press itself settles flat.
    static let releaseBounce = 0.2

    /// The shortest time a press shows for, however briefly the finger is down.
    static let minimumDown = 0.1

    /// The spring a control travels on, flat going down and springy coming back.
    ///
    /// - Parameter isDown: Whether the control is going down.
    /// - Returns: The animation for that direction.
    static func travel(isDown: Bool) -> Animation {
        isDown
            ? .spring(duration: pressDuration, bounce: 0.0)
            : .spring(duration: releaseDuration, bounce: releaseBounce)
    }

    /// How much longer a press shows for, after a finger down for `heldFor`.
    ///
    /// - Parameter heldFor: How long the finger was down.
    /// - Returns: The time left to hold, zero once the press has shown for long enough.
    static func remainingDown(heldFor: TimeInterval) -> TimeInterval {
        max(0.0, minimumDown - heldFor)
    }
}

extension View {
    /// Shrinks this view while a press is down, on the spring that press travels.
    ///
    /// - Parameter isDown: Whether the control is down.
    /// - Returns: The view, at the size the press leaves it.
    func sousPressScale(isDown: Bool) -> some View {
        scaleEffect(isDown ? ButtonPress.scale : 1.0)
            .animation(ButtonPress.travel(isDown: isDown), value: isDown)
    }
}
