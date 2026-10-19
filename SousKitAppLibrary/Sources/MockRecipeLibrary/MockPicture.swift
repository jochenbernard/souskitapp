import CoreGraphics
import Foundation

/// A picture drawn in code where a folder would hold a photo, so no picture ships with the app.
///
/// It draws a plate on a wash of its hue inside a frame along its edges, so a card cropping it shows which edges it
/// cut.
struct MockPicture: Sendable {
    /// The picture's color, as a hue from 0 to 1.
    let hue: Double

    /// The picture's width over its height.
    let aspectRatio: Double

    /// Draws the picture scaled to fill a box.
    ///
    /// - Parameter pixelSize: The box, in pixels.
    /// - Returns: The picture, reaching past the box on one side where its proportions differ.
    /// - Throws: `CocoaError.fileReadCorruptFile` where the picture cannot be drawn at that size.
    func thumbnail(filling pixelSize: CGSize) throws -> CGImage {
        let width = max(pixelSize.width, pixelSize.height * aspectRatio).rounded(.up)
        let height = (width / aspectRatio).rounded(.up)

        guard
            width >= 1.0,
            height >= 1.0,
            let space = CGColorSpace(name: CGColorSpace.sRGB),
            let context = CGContext(
                data: nil,
                width: Int(width),
                height: Int(height),
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: space,
                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
            )
        else {
            throw CocoaError(.fileReadCorruptFile)
        }

        draw(in: context, size: CGSize(width: width, height: height))

        guard let image = context.makeImage() else {
            throw CocoaError(.fileReadCorruptFile)
        }

        return image
    }

    private func draw(in context: CGContext, size: CGSize) {
        let bounds = CGRect(origin: .zero, size: size)
        let shortSide = min(size.width, size.height)

        context.setFillColor(color(saturation: 0.55, brightness: 0.8))
        context.fill(bounds)

        let frameWidth = shortSide * 0.03
        context.setStrokeColor(color(saturation: 0.0, brightness: 1.0))
        context.setLineWidth(frameWidth)
        context.stroke(bounds.insetBy(dx: frameWidth * 1.5, dy: frameWidth * 1.5))

        let plate = CGRect(
            x: bounds.midX - shortSide * 0.32,
            y: bounds.midY - shortSide * 0.32,
            width: shortSide * 0.64,
            height: shortSide * 0.64
        )
        context.setFillColor(color(saturation: 0.05, brightness: 0.97))
        context.fillEllipse(in: plate)
        context.setFillColor(color(saturation: 0.7, brightness: 0.55))
        context.fillEllipse(in: plate.insetBy(dx: shortSide * 0.1, dy: shortSide * 0.1))
    }

    /// The picture's hue at a saturation and brightness, each from 0 to 1.
    private func color(saturation: Double, brightness: Double) -> CGColor {
        let sector = (hue - hue.rounded(.down)) * 6.0
        let fraction = sector - sector.rounded(.down)
        let low = brightness * (1.0 - saturation)
        let falling = brightness * (1.0 - saturation * fraction)
        let rising = brightness * (1.0 - saturation * (1.0 - fraction))
        let components: [Double] = switch Int(sector) {
        case 0: [brightness, rising, low]
        case 1: [falling, brightness, low]
        case 2: [low, brightness, rising]
        case 3: [low, falling, brightness]
        case 4: [rising, low, brightness]
        default: [brightness, low, falling]
        }

        return CGColor(
            srgbRed: components[0],
            green: components[1],
            blue: components[2],
            alpha: 1.0
        )
    }
}
