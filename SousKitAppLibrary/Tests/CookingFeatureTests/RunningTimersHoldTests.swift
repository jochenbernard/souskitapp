@testable import CookingFeature
import CoreGraphics
import Testing

@Suite("Running timers hold")
struct RunningTimersHoldTests {
    private let distance = 120.0
    private let dimension = 600.0

    private func catching(
        openness: Double,
        rubberBand: CGFloat,
        canOpen: Bool = true
    ) -> RunningTimersHold {
        RunningTimersHold(
            catching: RunningTimersLayoutMetrics.Position(openness: openness, rubberBand: rubberBand),
            distance: distance,
            dimension: dimension,
            canOpen: canOpen
        )
    }

    @Test("within the ends the fold opens the timers as far as it goes")
    func withinEnds() {
        var hold = catching(openness: 1.0, rubberBand: 0.0)
        let position = hold.position(at: 30.0, distance: distance)

        #expect(abs(position.openness - 0.75) < 0.0001)
        #expect(position.rubberBand == 0.0)
    }

    @Test("past folded the fold pulls the timers down as a scroll view does")
    func pastFolded() {
        var hold = catching(openness: 1.0, rubberBand: 0.0)
        let position = hold.position(at: distance + 50.0, distance: distance)

        #expect(position.openness == 0.0)
        #expect(abs(position.rubberBand - RubberBand.offset(forPull: 50.0, dimension: dimension)) < 0.0001)
    }

    @Test(
        "a catch holds the timers where they are",
        arguments: [(0.3, 20.0), (0.86, -25.0), (1.02, 0.0), (-0.01, 0.0), (0.5, 0.0), (1.0, -12.0), (0.0, 18.0)]
    )
    func catchHolds(openness: Double, rubberBand: CGFloat) {
        var hold = catching(openness: openness, rubberBand: rubberBand)
        let position = hold.position(at: hold.fold, distance: distance)

        #expect(abs(position.openness - openness) < 0.0001)
        #expect(abs(position.rubberBand - rubberBand) < 0.0001)
    }

    @Test("a pull caught part of the way open goes before the timers open further")
    func pullGoesFirst() {
        var hold = catching(openness: 0.3, rubberBand: 20.0)
        let pull = RubberBand.pull(forOffset: 20.0, dimension: dimension)
        let letGo = hold.position(at: hold.fold - pull, distance: distance)
        let opened = hold.position(at: hold.fold - pull - 12.0, distance: distance)

        #expect(abs(letGo.openness - 0.3) < 0.0001)
        #expect(abs(letGo.rubberBand) < 0.0001)
        #expect(abs(opened.openness - 0.4) < 0.0001)
        #expect(opened.rubberBand == 0.0)
    }

    @Test("a pull caught part of the way open stays while the timers fold, and grows past folded")
    func foldUnderPull() {
        var hold = catching(openness: 0.3, rubberBand: 20.0)
        let folded = hold.position(at: hold.fold + 0.3 * distance, distance: distance)
        let further = hold.position(at: hold.fold + 0.3 * distance + 10.0, distance: distance)

        #expect(abs(folded.openness) < 0.0001)
        #expect(abs(folded.rubberBand - 20.0) < 0.0001)
        #expect(further.rubberBand > 20.0)
    }

    @Test("once the finger has let a caught pull go, it folds the timers as usual")
    func pullLetGo() {
        var hold = catching(openness: 0.3, rubberBand: 20.0)
        let start = hold.fold - RubberBand.pull(forOffset: 20.0, dimension: dimension)
        _ = hold.position(at: start - 12.0, distance: distance)
        let back = hold.position(at: start + 10.0, distance: distance)

        #expect(abs(back.openness - (1.0 - (start + 10.0) / distance)) < 0.0001)
        #expect(back.rubberBand == 0.0)
    }

    @Test(
        "a list that scrolls is open where its scrolling starts, however far past open it was caught",
        arguments: [(0.78, -18.0), (0.33, -170.0), (1.02, -30.0), (1.01, 0.0), (0.6, 0.0)]
    )
    func openAtScrollStart(openness: Double, rubberBand: CGFloat) {
        let caught = RunningTimersLayoutMetrics.Position(openness: openness, rubberBand: rubberBand).notPastOpen
        var hold = catching(openness: caught.openness, rubberBand: caught.rubberBand)
        let held = hold.position(at: hold.fold, distance: distance)
        let top = hold.position(at: 0.0, distance: distance)

        #expect(abs(held.openness - min(openness, 1.0)) < 0.0001)
        #expect(held.rubberBand == 0.0)
        #expect(top.openness == 1.0)
        #expect(top.rubberBand == 0.0)
    }

    @Test("a list the finger cannot open is only pulled past where it folds, whatever its openness")
    func cannotOpen() {
        var hold = catching(openness: 0.6, rubberBand: 0.0, canOpen: false)
        let raised = hold.position(at: distance - 20.0, distance: distance)
        let lowered = hold.position(at: distance + 20.0, distance: distance)

        #expect(abs(hold.fold - distance) < 0.0001)
        #expect(raised.openness == 0.0)
        #expect(raised.rubberBand < 0.0)
        #expect(lowered.rubberBand > 0.0)
    }
}
