import CoreGraphics
@testable import DesignSystem
import Testing

@Suite("Flow layout")
struct SousFlowLayoutTests {
    private let chip = CGSize(width: 60.0, height: 28.0)
    private let spacing = 8.0

    @Test("views wrap onto a new row where the next one does not fit")
    func wraps() {
        let sizes = Array(repeating: chip, count: 5)

        #expect(SousFlowLayout.rowCount(of: sizes, width: 200.0, spacing: spacing) == 2)
        #expect(SousFlowLayout.rowCount(of: sizes, width: 340.0, spacing: spacing) == 1)
    }

    @Test("the narrowest width holds the views in the rows given, and a point less does not")
    func narrowestWidth() {
        let sizes = Array(repeating: chip, count: 5)
        let width = SousFlowLayout.narrowestWidth(
            of: sizes,
            spacing: spacing,
            rowCount: 2
        )

        #expect(SousFlowLayout.rowCount(of: sizes, width: width, spacing: spacing) == 2)
        #expect(SousFlowLayout.rowCount(of: sizes, width: width - 1.0, spacing: spacing) == 3)
        #expect(abs(width - 196.0) <= 0.5)
    }

    @Test("the narrowest width is never narrower than the widest view")
    func narrowestWidthHoldsTheWidestView() {
        let sizes = [chip, CGSize(width: 150.0, height: 28.0), chip]

        #expect(
            SousFlowLayout.narrowestWidth(
                of: sizes,
                spacing: spacing,
                rowCount: 3
            ) == 150.0
        )
    }

    @Test("no views take no width")
    func noViews() {
        #expect(
            SousFlowLayout.narrowestWidth(
                of: [],
                spacing: spacing,
                rowCount: 2
            ) == 0.0
        )
    }
}
