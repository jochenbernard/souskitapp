@testable import DesignSystem
import SwiftUI
import Testing

@Suite("The mark")
struct SousMarkTests {
    /// The distance from a stroked path to its ink edge.
    private static let halfStroke = SousMarkShape.strokeWidth / 2.0

    @Test("the three-curl cut sits on the documented axes")
    func threeCurlGeometry() {
        let cut = SousMark.Cut.threeCurl
        #expect(cut.outerCurlAxes == [20.0, 44.0])
        #expect(cut.middleCurlAxis == 32.0)
        #expect(cut.plateStart == 18.0)
        #expect(cut.plateEnd == 46.0)
    }

    @Test("the two-curl cut sits on the documented axes")
    func twoCurlGeometry() {
        let cut = SousMark.Cut.twoCurl
        #expect(cut.outerCurlAxes == [26.0])
        #expect(cut.middleCurlAxis == 38.0)
        #expect(cut.plateStart == 22.0)
        #expect(cut.plateEnd == 42.0)
    }

    @Test("a 6-unit gap separates the curls from the plate")
    func curlsNeverTouchThePlate() {
        let curlEdge = SousMarkShape.curlBottom + Self.halfStroke
        let plateEdge = SousMarkShape.plateY - Self.halfStroke
        #expect(plateEdge - curlEdge == 6.0)
    }

    @Test("curls are pitched 12 units apart and stand 14 units tall")
    func curlPitchAndHeight() {
        let axes = (SousMark.Cut.threeCurl.outerCurlAxes
            + [SousMark.Cut.threeCurl.middleCurlAxis]).sorted()
        let pitches = zip(axes, axes.dropFirst()).map({ $1 - $0 })

        #expect(pitches == [12.0, 12.0])
        #expect(SousMarkShape.curlBottom - SousMarkShape.curlTop == 14.0)
    }

    @Test("the plate sits under the outer curls", arguments: [SousMark.Cut.threeCurl, .twoCurl])
    func plateSitsUnderTheOuterCurls(cut: SousMark.Cut) {
        let outermost = cut.outerCurlAxes + [cut.middleCurlAxis]
        let inkBox = SousMarkShape.plateY + Self.halfStroke
            - (SousMarkShape.curlTop - Self.halfStroke)

        #expect(cut.plateStart < (outermost.min() ?? 0.0))
        #expect(cut.plateEnd > (outermost.max() ?? 0.0))
        #expect(cut.plateEnd - cut.plateStart < inkBox)
    }

    @Test("the 64-unit grid holds a 36-unit ink box and one curl of clearspace")
    func clearspaceIsBuiltIn() {
        let inkTop = SousMarkShape.curlTop - Self.halfStroke
        let inkBottom = SousMarkShape.plateY + Self.halfStroke
        let curlHeight = SousMarkShape.curlBottom - SousMarkShape.curlTop

        #expect(inkBottom - inkTop == 36.0)
        #expect(inkTop == curlHeight)
        #expect(SousMarkShape.gridSize - inkBottom == curlHeight)
    }

    @Test("on light the automatic cut holds three curls at the 24pt floor")
    func automaticCutHoldsAtTheFloorOnLight() {
        #expect(SousMark.Cut.automatic.resolved(size: 24.0, colorScheme: .light) == .threeCurl)
        #expect(SousMark.Cut.automatic.resolved(size: 23.9, colorScheme: .light) == .twoCurl)
    }

    @Test("an explicit cut overrides the floor")
    func explicitCutOverridesTheFloor() {
        #expect(SousMark.Cut.threeCurl.resolved(size: 16.0, colorScheme: .light) == .threeCurl)
        #expect(SousMark.Cut.twoCurl.resolved(size: 64.0, colorScheme: .light) == .twoCurl)
    }

    @Test("the automatic colorway is the light cut on a light scheme")
    func automaticColorwayFollowsTheScheme() {
        #expect(SousMark.Colorway.automatic.resolved(colorScheme: .light) == .primary)
        #expect(SousMark.Colorway.mono.resolved(colorScheme: .light) == .mono)
    }
}
