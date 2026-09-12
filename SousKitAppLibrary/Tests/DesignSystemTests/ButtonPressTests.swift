@testable import DesignSystem
import Testing

@MainActor
@Suite("Button press")
struct ButtonPressTests {
    @Test("a tap shorter than the minimum is held out to it")
    func shortTapIsHeldOut() {
        let held = 0.03
        let remaining = ButtonPress.remainingDown(heldFor: held)
        #expect(abs((held + remaining) - ButtonPress.minimumDown) < 0.0001)
    }

    @Test("a press past the minimum is released at once")
    func longPressIsNotHeld() {
        #expect(ButtonPress.remainingDown(heldFor: ButtonPress.minimumDown) == 0.0)
        #expect(ButtonPress.remainingDown(heldFor: 0.5) == 0.0)
    }
}
