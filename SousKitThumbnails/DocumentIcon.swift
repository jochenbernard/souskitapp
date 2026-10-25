import UIKit

/// The Sous document icon: the mark, as the app draws it on a light ground, on a page with a folded corner.
enum DocumentIcon {
    // A page's width for its height, as a sheet of paper has.
    private static let aspectRatio: CGFloat = 0.77

    // The mark's grid, stroke and curls, as `SousMarkShape` in the design system draws the three-curl cut.
    private static let gridSize: CGFloat = 64.0
    private static let strokeWidth: CGFloat = 8.0
    private static let curlTop: CGFloat = 18.0
    private static let curlBottom: CGFloat = 32.0
    private static let curlThrow: CGFloat = 3.0
    private static let upperControlY: CGFloat = 23.0
    private static let lowerControlY: CGFloat = 27.0
    private static let outerCurlAxes: [CGFloat] = [20.0, 44.0]
    private static let middleCurlAxis: CGFloat = 32.0
    private static let plateStart: CGFloat = 18.0
    private static let plateEnd: CGFloat = 46.0
    private static let plateY: CGFloat = 46.0

    // The accent, as the app icon fills it.
    private static let accent = UIColor(cgColor: CGColor(
        srgbRed: 0.91765,
        green: 0.32157,
        blue: 0.00784,
        alpha: 1.0
    ))

    /// The largest page that fits a size.
    ///
    /// - Parameter maximumSize: The size the page fits in.
    /// - Returns: The page's size.
    static func size(fitting maximumSize: CGSize) -> CGSize {
        let height = min(maximumSize.height, maximumSize.width / aspectRatio)

        return CGSize(width: height * aspectRatio, height: height)
    }

    /// Draws the icon into the current graphics context, filling a rect.
    ///
    /// - Parameter rect: The rect, at the page's proportions.
    static func draw(in rect: CGRect) {
        let border = max(1.0, rect.width / 64.0)
        let page = rect.insetBy(dx: border / 2.0, dy: border / 2.0)
        let fold = page.width * 0.24
        let radius = page.width * 0.05

        let outline = pagePath(page, fold: fold, radius: radius)
        UIColor.white.setFill()
        outline.fill()
        UIColor.black.withAlphaComponent(0.16).setStroke()
        outline.lineWidth = border
        outline.stroke()

        let corner = UIBezierPath()
        corner.move(to: CGPoint(x: page.maxX - fold, y: page.minY))
        corner.addLine(to: CGPoint(x: page.maxX - fold, y: page.minY + fold - radius))
        corner.addQuadCurve(
            to: CGPoint(x: page.maxX - fold + radius, y: page.minY + fold),
            controlPoint: CGPoint(x: page.maxX - fold, y: page.minY + fold)
        )
        corner.addLine(to: CGPoint(x: page.maxX, y: page.minY + fold))
        corner.close()
        UIColor.black.withAlphaComponent(0.1).setFill()
        corner.fill()
        corner.lineWidth = border
        corner.lineJoinStyle = .round
        corner.stroke()

        let edge = page.width * 0.8
        drawMark(in: CGRect(
            x: page.midX - (edge / 2.0),
            y: page.minY + (page.height * 0.56) - (edge / 2.0),
            width: edge,
            height: edge
        ))
    }

    private static func pagePath(_ page: CGRect, fold: CGFloat, radius: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: page.minX + radius, y: page.minY))
        path.addLine(to: CGPoint(x: page.maxX - fold, y: page.minY))
        path.addLine(to: CGPoint(x: page.maxX, y: page.minY + fold))
        path.addLine(to: CGPoint(x: page.maxX, y: page.maxY - radius))
        path.addQuadCurve(
            to: CGPoint(x: page.maxX - radius, y: page.maxY),
            controlPoint: CGPoint(x: page.maxX, y: page.maxY)
        )
        path.addLine(to: CGPoint(x: page.minX + radius, y: page.maxY))
        path.addQuadCurve(
            to: CGPoint(x: page.minX, y: page.maxY - radius),
            controlPoint: CGPoint(x: page.minX, y: page.maxY)
        )
        path.addLine(to: CGPoint(x: page.minX, y: page.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: page.minX + radius, y: page.minY),
            controlPoint: CGPoint(x: page.minX, y: page.minY)
        )
        path.close()

        return path
    }

    private static func drawMark(in square: CGRect) {
        let scale = square.width / gridSize

        func point(_ column: CGFloat, _ row: CGFloat) -> CGPoint {
            CGPoint(x: square.minX + (column * scale), y: square.minY + (row * scale))
        }

        func stroke(_ path: UIBezierPath, _ color: UIColor) {
            path.lineWidth = strokeWidth * scale
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            color.setStroke()
            path.stroke()
        }

        func curl(at axis: CGFloat) -> UIBezierPath {
            let path = UIBezierPath()
            path.move(to: point(axis, curlBottom))
            path.addCurve(
                to: point(axis, curlTop),
                controlPoint1: point(axis + curlThrow, lowerControlY),
                controlPoint2: point(axis - curlThrow, upperControlY)
            )

            return path
        }

        for axis in outerCurlAxes {
            stroke(curl(at: axis), .black)
        }

        stroke(curl(at: middleCurlAxis), accent)

        let plate = UIBezierPath()
        plate.move(to: point(plateStart, plateY))
        plate.addLine(to: point(plateEnd, plateY))
        stroke(plate, .black)
    }
}
