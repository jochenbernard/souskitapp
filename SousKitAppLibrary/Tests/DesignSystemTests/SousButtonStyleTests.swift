@testable import DesignSystem
import Testing

@MainActor
@Suite("Button press")
struct SousButtonStyleTests {
    @Test("a tap shorter than the minimum is held out to it")
    func shortTapIsHeldOut() {
        let held = 0.03
        let remaining = SousButtonStyle.remainingDown(heldFor: held)
        #expect(abs((held + remaining) - SousButtonStyle.minimumDown) < 0.0001)
    }

    @Test("a press past the minimum is released at once")
    func longPressIsNotHeld() {
        #expect(SousButtonStyle.remainingDown(heldFor: SousButtonStyle.minimumDown) == 0.0)
        #expect(SousButtonStyle.remainingDown(heldFor: 0.5) == 0.0)
    }
}
