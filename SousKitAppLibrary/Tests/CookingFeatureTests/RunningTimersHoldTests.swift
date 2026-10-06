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
        heldBounce: CGFloat = 0.0,
        canOpen: Bool = true
    ) -> RunningTimersHold {
        RunningTimersHold(
            catching: RunningTimersLayoutMetrics.Position(
                openness: openness,
                rubberBand: rubberBand,
                heldBounce: heldBounce
            ),
            distance: distance,
            dimension: dimension,
            canOpen: canOpen
        )
    }

    // Walks the fold from where the hold caught the timers in half-point steps, none of which may jump them.
    private func expectNoJump(_ hold: inout RunningTimersHold, directions: [Double]) {
        let step = 0.5
        var amount = hold.fold
        var previous = hold.position(at: amount)

        for direction in directions {
            amount += direction * step
            let position = hold.position(at: amount)

            #expect(abs(position.openness - previous.openness) <= step / hold.distance + 0.0001)
            #expect(abs(position.rubberBand - previous.rubberBand) <= step + 0.0001)
            #expect(abs(position.heldBounce - previous.heldBounce) <= step + 0.0001)
            previous = position
        }
    }

    @Test("within the ends the fold opens the timers as far as it goes")
    func withinEnds() {
        var hold = catching(openness: 1.0, rubberBand: 0.0)
        let position = hold.position(at: 30.0)

        #expect(abs(position.openness - 0.75) < 0.0001)
        #expect(position.rubberBand == 0.0)
    }

    @Test("past folded the fold pulls the timers down as a scroll view does")
    func pastFolded() {
        var hold = catching(openness: 1.0, rubberBand: 0.0)
        let position = hold.position(at: distance + 50.0)

        #expect(position.openness == 0.0)
        #expect(abs(position.rubberBand - RubberBand.offset(forPull: 50.0, dimension: dimension)) < 0.0001)
    }

    @Test(
        "a catch past one end and pulled past the other moves on without a jump",
        arguments: [(1.03, 7.0), (-0.05, -10.0)]
    )
    func pastOneEndPulledPastOther(openness: Double, rubberBand: CGFloat) {
        var hold = catching(openness: openness, rubberBand: rubberBand)

        expectNoJump(&hold, directions: Array(repeating: 1.0, count: 80) + Array(repeating: -1.0, count: 160))
    }

    @Test("a pull caught part of the way open goes before the timers open further")
    func pullGoesFirst() {
        var hold = catching(openness: 0.3, rubberBand: 20.0)
        let pull = RubberBand.pull(forOffset: 20.0, dimension: dimension)
        let letGo = hold.position(at: hold.fold - pull)
        let opened = hold.position(at: hold.fold - pull - 12.0)

        #expect(abs(letGo.openness - 0.3) < 0.0001)
        #expect(abs(letGo.rubberBand) < 0.0001)
        #expect(abs(opened.openness - 0.4) < 0.0001)
        #expect(opened.rubberBand == 0.0)
    }

    @Test("a pull caught part of the way open stays while the timers fold, and grows past folded")
    func foldUnderPull() {
        var hold = catching(openness: 0.3, rubberBand: 20.0)
        let folded = hold.position(at: hold.fold + 0.3 * distance)
        let further = hold.position(at: hold.fold + 0.3 * distance + 10.0)

        #expect(abs(folded.openness) < 0.0001)
        #expect(abs(folded.rubberBand - 20.0) < 0.0001)
        #expect(further.rubberBand > 20.0)
    }

    @Test("once the finger has let a caught pull go, it folds the timers as usual")
    func pullLetGo() {
        var hold = catching(openness: 0.3, rubberBand: 20.0)
        let start = hold.fold - RubberBand.pull(forOffset: 20.0, dimension: dimension)
        _ = hold.position(at: start - 12.0)
        let back = hold.position(at: start + 10.0)

        #expect(abs(back.openness - (1.0 - (start + 10.0) / distance)) < 0.0001)
        #expect(back.rubberBand == 0.0)
    }

    @Test(
        "a list that scrolls is open where its scrolling starts, however far past open it was caught",
        arguments: [(0.78, -18.0), (0.33, -170.0), (1.02, -30.0), (1.01, 0.0), (0.6, 0.0)]
    )
    func openAtScrollStart(openness: Double, rubberBand: CGFloat) {
        let caught = RunningTimersLayoutMetrics.Position(
            openness: openness,
            rubberBand: rubberBand,
            heldBounce: 0.0
        ).notPastOpen
        var hold = catching(openness: caught.openness, rubberBand: caught.rubberBand)
        let held = hold.position(at: hold.fold)
        let top = hold.position(at: 0.0)

        #expect(abs(held.openness - min(openness, 1.0)) < 0.0001)
        #expect(held.rubberBand == 0.0)
        #expect(top.openness == 1.0)
        #expect(top.rubberBand == 0.0)
    }

    @Test("a list the finger cannot open is only pulled past where it folds, whatever its openness")
    func cannotOpen() {
        var hold = catching(
            openness: 0.6,
            rubberBand: 0.0,
            canOpen: false
        )
        let raised = hold.position(at: distance - 20.0)
        let lowered = hold.position(at: distance + 20.0)

        #expect(abs(hold.fold - distance) < 0.0001)
        #expect(raised.openness == 0.0)
        #expect(raised.rubberBand < 0.0)
        #expect(lowered.rubberBand > 0.0)
    }

    @Test(
        "a catch holds the timers where they are, a bounce past the top included",
        arguments: [
            (0.3, 20.0, 0.0),
            (0.86, -25.0, 0.0),
            (1.02, 0.0, 0.0),
            (-0.01, 0.0, 0.0),
            (0.5, 0.0, 0.0),
            (1.0, -12.0, 0.0),
            (0.0, 18.0, 0.0),
            (1.03, 7.0, 0.0),
            (-0.05, -10.0, 0.0),
            (1.0, 0.0, 30.0),
            (0.7, 0.0, 30.0),
            (1.04, 0.0, 12.0),
            (0.4, 15.0, 20.0),
            (1.02, -6.0, -3.0)
        ]
    )
    func catchHolds(
        openness: Double,
        rubberBand: CGFloat,
        heldBounce: CGFloat
    ) {
        var hold = catching(
            openness: openness,
            rubberBand: rubberBand,
            heldBounce: heldBounce
        )
        let position = hold.position(at: hold.fold)

        #expect(abs(position.openness - openness) < 0.0001)
        #expect(abs(position.rubberBand - rubberBand) < 0.0001)
        #expect(abs(position.heldBounce - heldBounce) < 0.0001)
    }

    @Test("a caught bounce folds the timers from where it holds them, the rest of their travel to the stack")
    func bounceFolds() {
        var hold = catching(
            openness: 1.0,
            rubberBand: 0.0,
            heldBounce: 30.0
        )
        let halfway = hold.position(at: 30.0 + (distance - 30.0) / 2.0)

        #expect(abs(halfway.openness - 0.5) < 0.0001)
        #expect(halfway.heldBounce == 30.0)
        #expect(halfway.rubberBand == 0.0)
    }

    @Test("short of open, the finger takes a caught bounce up before it pulls the timers past open")
    func bounceGoesBeforeStretch() {
        var hold = catching(
            openness: 1.0,
            rubberBand: 0.0,
            heldBounce: 30.0
        )
        let partway = hold.position(at: 10.0)
        let top = hold.position(at: 0.0)
        let stretched = hold.position(at: -20.0)

        #expect(abs(partway.heldBounce - 10.0) < 0.0001)
        #expect(partway.openness == 1.0)
        #expect(partway.rubberBand == 0.0)
        #expect(top.heldBounce == 0.0)
        #expect(top.rubberBand == 0.0)
        #expect(stretched.heldBounce == 0.0)
        #expect(abs(stretched.rubberBand + RubberBand.offset(forPull: 20.0, dimension: dimension)) < 0.0001)
    }

    @Test("a bounce caught past open keeps the timers that far open while the finger takes the bounce up")
    func bounceCaughtPastOpen() {
        var hold = catching(
            openness: 1.04,
            rubberBand: 0.0,
            heldBounce: 12.0
        )
        let start = hold.fold
        let raised = hold.position(at: start - 5.0)
        let lowered = hold.position(at: start + 2.0)

        #expect(abs(raised.openness - 1.04) < 0.0001)
        #expect(abs(raised.heldBounce - 7.0) < 0.0001)
        #expect(raised.rubberBand == 0.0)
        #expect(lowered.openness < 1.04)
        #expect(lowered.heldBounce == 12.0)
    }

    @Test("a caught bounce moves on without a jump either way")
    func bounceMovesOn() {
        var hold = catching(
            openness: 0.9,
            rubberBand: 0.0,
            heldBounce: 25.0
        )

        expectNoJump(&hold, directions: Array(repeating: -1.0, count: 160) + Array(repeating: 1.0, count: 400))
    }
}
