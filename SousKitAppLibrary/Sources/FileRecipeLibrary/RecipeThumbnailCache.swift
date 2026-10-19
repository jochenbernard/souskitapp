import CoreGraphics
import CryptoKit
import Foundation
import ImageIO
import RecipeLibrary
import UniformTypeIdentifiers

/// The thumbnails of one directory's pictures, kept between launches in a folder the system may clear.
///
/// A thumbnail is found by its picture's path, the picture's modification date, and the size it fills, so a picture
/// replaced in the directory is never shown as it was. A picture telling no date is never kept.
struct RecipeThumbnailCache: Sendable {
    private static let jpegQuality = 0.85

    private let directoryPath: String
    private let folderURL: URL

    /// Creates a cache.
    ///
    /// - Parameters:
    ///   - recipeDirectory: The directory whose pictures are kept.
    ///   - folderURL: Where the thumbnails are kept, outside the directory.
    init(recipeDirectory: RecipeDirectory, folderURL: URL) {
        self.directoryPath = recipeDirectory.url.standardizedFileURL.path(percentEncoded: false)
        self.folderURL = folderURL
    }

    /// The thumbnail kept for a picture as it is now, at a size.
    ///
    /// - Parameters:
    ///   - picture: The picture.
    ///   - pixelSize: The box the thumbnail fills, in pixels.
    /// - Returns: The thumbnail, decoded, or `nil` where none is kept.
    func thumbnail(of picture: RecipePicture, filling pixelSize: CGSize) -> CGImage? {
        guard
            let fileURL = fileURL(of: picture, filling: pixelSize),
            let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil)
        else {
            return nil
        }

        return CGImageSourceCreateImageAtIndex(
            source,
            0,
            [kCGImageSourceShouldCacheImmediately: true] as CFDictionary
        )
    }

    /// Keeps a picture's thumbnail at a size.
    ///
    /// A thumbnail that cannot be written is made again the next time, so a failure is dropped.
    ///
    /// - Parameters:
    ///   - thumbnail: The thumbnail.
    ///   - picture: The picture it was made from.
    ///   - pixelSize: The box the thumbnail fills, in pixels.
    func save(
        _ thumbnail: CGImage,
        of picture: RecipePicture,
        filling pixelSize: CGSize
    ) {
        guard let fileURL = fileURL(of: picture, filling: pixelSize) else {
            return
        }

        // A JPEG is a fraction of a PNG's size; only a thumbnail that can be seen through needs the PNG.
        let isOpaque = [.none, .noneSkipFirst, .noneSkipLast].contains(thumbnail.alphaInfo)
        let type = isOpaque ? UTType.jpeg : UTType.png
        let data = NSMutableData()

        guard
            let destination = CGImageDestinationCreateWithData(
                data,
                type.identifier as CFString,
                1,
                nil
            )
        else {
            return
        }

        CGImageDestinationAddImage(
            destination,
            thumbnail,
            [kCGImageDestinationLossyCompressionQuality: Self.jpegQuality] as CFDictionary
        )

        guard CGImageDestinationFinalize(destination) else {
            return
        }

        try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        try? data.write(to: fileURL, options: .atomic)
    }

    /// Where a picture's thumbnail at a size is kept, or `nil` for a picture telling no date.
    private func fileURL(of picture: RecipePicture, filling pixelSize: CGSize) -> URL? {
        guard let modificationDate = picture.modificationDate else {
            return nil
        }

        let key = [
            directoryPath,
            picture.id,
            String(modificationDate.timeIntervalSinceReferenceDate),
            String(Int(pixelSize.width.rounded())),
            String(Int(pixelSize.height.rounded()))
        ]
        .joined(separator: "\n")
        let name = SHA256.hash(data: Data(key.utf8)).map({ String(format: "%02x", $0) }).joined()

        return folderURL.appending(path: name)
    }
}
