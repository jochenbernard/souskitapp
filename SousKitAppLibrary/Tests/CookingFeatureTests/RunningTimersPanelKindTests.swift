@testable import CookingFeature
import SwiftUI
import Testing

@Suite("Running timers panel kind")
struct RunningTimersPanelKindTests {
    private func kind(_ horizontalSizeClass: UserInterfaceSizeClass?, width: CGFloat) -> RunningTimersPanel.Kind {
        RunningTimersPanel.Kind(
            horizontalSizeClass: horizontalSizeClass,
            width: width,
            columnWidth: 356.0,
            minimumStepsWidth: 340.0
        )
    }

    @Test(
        "a wide screen that leaves the steps their room shows the timers beside them",
        arguments: [696.0, 834.0, 1_210.0, .infinity]
    )
    func roomBeside(width: CGFloat) {
        #expect(kind(.regular, width: width) == .column)
    }

    @Test(
        "a wide screen that leaves the steps less than their room folds the timers over them",
        arguments: [695.5, 672.0, 356.0, 0.0]
    )
    func noRoomBeside(width: CGFloat) {
        #expect(kind(.regular, width: width) == .folding)
    }

    @Test(
        "any other screen folds the timers over the steps, whatever room it has",
        arguments: [UserInterfaceSizeClass.compact, nil]
    )
    func notWide(horizontalSizeClass: UserInterfaceSizeClass?) {
        #expect(kind(horizontalSizeClass, width: 1_210.0) == .folding)
    }

    @Test("timers and steps that take more room fold on a screen that held them before")
    func moreRoomTaken() {
        let kind = RunningTimersPanel.Kind(
            horizontalSizeClass: .regular,
            width: 834.0,
            columnWidth: 429.0,
            minimumStepsWidth: 435.0
        )

        #expect(kind == .folding)
    }
}
