import SwiftUI

/// One stroked part of the mark, drawn on the 64-unit grid and scaled to fit a rect.
///
/// The parts are separate shapes because the middle curl takes its own stroke color.
struct SousMarkShape: Shape {
    /// Which part of the mark to draw.
    enum Part {
        /// The curls either side of the middle one.
        case outerCurls

        /// The middle curl, the only part that takes the accent.
        case middleCurl

        /// The plate.
        case plate
    }

    /// Maps the 64-unit grid onto a rect, square and centered.
    private struct Grid {
        let origin: CGPoint
        let scale: CGFloat

        init(fitting rect: CGRect) {
            self.scale = min(rect.width, rect.height) / SousMarkShape.gridSize
            let edge = SousMarkShape.gridSize * scale
            self.origin = CGPoint(x: rect.midX - (edge / 2.0), y: rect.midY - (edge / 2.0))
        }

        func point(column: CGFloat, row: CGFloat) -> CGPoint {
            CGPoint(x: origin.x + (column * scale), y: origin.y + (row * scale))
        }
    }

    /// The side of the grid, in units.
    static let gridSize: CGFloat = 64.0

    /// The one stroke weight, in units.
    static let strokeWidth: CGFloat = 8.0

    /// The top of a curl, in units.
    static let curlTop: CGFloat = 18.0

    /// The bottom of a curl, in units.
    static let curlBottom: CGFloat = 32.0

    /// How far a curl's control points sit either side of its axis, in units.
    static let curlThrow: CGFloat = 3.0

    /// The row the plate sits on, in units.
    static let plateY: CGFloat = 46.0

    let part: Part
    let cut: SousMark.Cut

    /// The stroke every part is drawn with, scaled for a mark `size` points on a side.
    ///
    /// - Parameter size: The edge of the grid, in points.
    /// - Returns: The stroke, round at its caps and joins.
    static func strokeStyle(size: CGFloat) -> StrokeStyle {
        StrokeStyle(
            lineWidth: strokeWidth * size / gridSize,
            lineCap: .round,
            lineJoin: .round
        )
    }

    func path(in rect: CGRect) -> Path {
        let grid = Grid(fitting: rect)
        var path = Path()

        switch part {
        case .outerCurls:
            for axis in cut.outerCurlAxes {
                Self.addCurl(
                    to: &path,
                    axis: axis,
                    on: grid
                )
            }
        case .middleCurl:
            Self.addCurl(
                to: &path,
                axis: cut.middleCurlAxis,
                on: grid
            )
        case .plate:
            path.move(to: grid.point(column: cut.plateStart, row: Self.plateY))
            path.addLine(to: grid.point(column: cut.plateEnd, row: Self.plateY))
        }

        return path
    }

    private static let upperControlY: CGFloat = 23.0
    private static let lowerControlY: CGFloat = 27.0

    /// Appends one S-bend rising 14 units about an axis.
    private static func addCurl(
        to path: inout Path,
        axis: CGFloat,
        on grid: Grid
    ) {
        path.move(to: grid.point(column: axis, row: curlBottom))
        path.addCurve(
            to: grid.point(column: axis, row: curlTop),
            control1: grid.point(column: axis + curlThrow, row: lowerControlY),
            control2: grid.point(column: axis - curlThrow, row: upperControlY)
        )
    }
}

#Preview("Parts") {
    let edge = 96.0
    let stroke = SousMarkShape.strokeStyle(size: edge)

    HStack(spacing: SousSpacing.large) {
        SousMarkShape(part: .outerCurls, cut: .threeCurl)
            .stroke(style: stroke)

        SousMarkShape(part: .middleCurl, cut: .threeCurl)
            .stroke(style: stroke)

        SousMarkShape(part: .plate, cut: .threeCurl)
            .stroke(style: stroke)
    }
    .frame(height: edge)
    .padding(SousSpacing.xLarge)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.groupedBackground)
}

#Preview("Both cuts") {
    let edge = 96.0
    let stroke = SousMarkShape.strokeStyle(size: edge)

    HStack(spacing: SousSpacing.large) {
        ForEach([SousMark.Cut.threeCurl, .twoCurl], id: \.self) { cut in
            ZStack {
                SousMarkShape(part: .outerCurls, cut: cut)
                    .stroke(style: stroke)

                SousMarkShape(part: .plate, cut: cut)
                    .stroke(style: stroke)

                SousMarkShape(part: .middleCurl, cut: cut)
                    .stroke(.accent, style: stroke)
            }
            .frame(width: edge, height: edge)
        }
    }
    .padding(SousSpacing.xLarge)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.groupedBackground)
}
