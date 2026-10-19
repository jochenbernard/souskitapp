import CoreGraphics
import Foundation
import ImageIO

/// Scales pictures down to the size a card shows them at.
enum RecipeThumbnailMaker {
    /// The picture in a file, scaled down to fill a box, upright.
    ///
    /// - Parameters:
    ///   - url: The file.
    ///   - pixelSize: The box, in pixels.
    /// - Returns: The picture, decoded, keeping its proportions and never larger than the file holds it.
    /// - Throws: `CocoaError.fileReadCorruptFile` where the file holds no picture.
    static func thumbnail(ofImageAt url: URL, filling pixelSize: CGSize) throws -> CGImage {
        guard
            let source = CGImageSourceCreateWithURL(url as CFURL, [kCGImageSourceShouldCache: false] as CFDictionary),
            let size = uprightSize(of: source),
            size.width > 0.0,
            size.height > 0.0
        else {
            throw CocoaError(.fileReadCorruptFile)
        }

        let scale = min(1.0, max(pixelSize.width / size.width, pixelSize.height / size.height))
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: (max(size.width, size.height) * scale).rounded(.up)
        ]

        guard
            let thumbnail = CGImageSourceCreateThumbnailAtIndex(
                source,
                0,
                options as CFDictionary
            )
        else {
            throw CocoaError(.fileReadCorruptFile)
        }

        return thumbnail
    }

    /// The size of a source's first picture as it is shown, turned by its orientation.
    private static func uprightSize(of source: CGImageSource) -> CGSize? {
        guard
            let properties = CGImageSourceCopyPropertiesAtIndex(
                source,
                0,
                nil
            ) as? [CFString: Any],
            let width = properties[kCGImagePropertyPixelWidth] as? Double,
            let height = properties[kCGImagePropertyPixelHeight] as? Double
        else {
            return nil
        }

        // Orientations 5 to 8 turn the picture a quarter, swapping its sides.
        let orientation = properties[kCGImagePropertyOrientation] as? UInt32 ?? 1

        return orientation >= 5 ? CGSize(width: height, height: width) : CGSize(width: width, height: height)
    }
}
