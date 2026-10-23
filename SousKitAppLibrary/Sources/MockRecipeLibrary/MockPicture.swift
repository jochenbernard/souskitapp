import UIKit

/// A picture drawn in code where a folder would hold a photo, so no picture ships with the app.
///
/// It shows its dish's emoji on a gingham tablecloth.
struct MockPicture: Sendable {
    /// What the picture shows.
    let dish: MockDish

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

    private static func color(_ hex: Int, alpha: Double = 1.0) -> CGColor {
        CGColor(
            srgbRed: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            alpha: alpha
        )
    }

    private func draw(in context: CGContext, size: CGSize) {
        let bounds = CGRect(origin: .zero, size: size)
        let shortSide = min(size.width, size.height)

        // UIKit's coordinates, so the emoji draws upright and the checks start at the top edge.
        context.translateBy(x: 0.0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)

        drawCloth(in: context, bounds: bounds, checkWidth: shortSide / 7.0)
        drawVignette(in: context, bounds: bounds)
        drawDish(in: context, bounds: bounds, shortSide: shortSide)
    }

    private func drawCloth(in context: CGContext, bounds: CGRect, checkWidth: Double) {
        context.setFillColor(Self.color(0xFBF8F2))
        context.fill(bounds)

        // Translucent, so the checks where the stripes cross come out darker, as a woven gingham's do.
        context.setFillColor(clothColor(alpha: 0.42))
        for left in stride(from: -checkWidth / 2.0, to: bounds.maxX, by: checkWidth * 2.0) {
            context.fill(CGRect(x: left, y: 0.0, width: checkWidth, height: bounds.height))
        }
        for top in stride(from: -checkWidth / 2.0, to: bounds.maxY, by: checkWidth * 2.0) {
            context.fill(CGRect(x: 0.0, y: top, width: bounds.width, height: checkWidth))
        }
    }

    private func clothColor(alpha: Double) -> CGColor {
        switch dish.cloth {
        case .blue:
            Self.color(0x3E6FB0, alpha: alpha)
        case .red:
            Self.color(0xC0392B, alpha: alpha)
        case .green:
            Self.color(0x4E8A4A, alpha: alpha)
        }
    }

    private func drawVignette(in context: CGContext, bounds: CGRect) {
        let clear = CGColor(gray: 0.0, alpha: 0.0)

        guard
            let gradient = CGGradient(
                colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                colors: [clear, clear, CGColor(gray: 0.0, alpha: 0.18)] as CFArray,
                locations: [0.0, 0.45, 1.0]
            )
        else {
            return
        }

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        context.drawRadialGradient(
            gradient,
            startCenter: center,
            startRadius: 0.0,
            endCenter: center,
            endRadius: hypot(bounds.width, bounds.height) / 2.0,
            options: .drawsAfterEndLocation
        )
    }

    private func drawDish(in context: CGContext, bounds: CGRect, shortSide: Double) {
        let emoji = NSAttributedString(
            string: dish.emoji,
            attributes: [.font: UIFont.systemFont(ofSize: shortSide * 0.52)]
        )
        let emojiSize = emoji.size()

        context.saveGState()
        context.setShadow(
            offset: CGSize(width: 0.0, height: shortSide * 0.03),
            blur: shortSide * 0.05,
            color: CGColor(gray: 0.0, alpha: 0.3)
        )
        UIGraphicsPushContext(context)
        emoji.draw(at: CGPoint(x: bounds.midX - emojiSize.width / 2.0, y: bounds.midY - emojiSize.height / 2.0))
        UIGraphicsPopContext()
        context.restoreGState()
    }
}
