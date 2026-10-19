import CoreGraphics
import CryptoKit
import Foundation
import ImageIO
import RecipeLibrary
import UniformTypeIdentifiers

/// The thumbnails of one directory's pictures, kept between launches in a folder the system may clear.
///
/// A thumbnail is found by its picture's path, the picture's modification date, and the size it fills, so a picture
/// replaced in the directory is never shown as it was. A picture telling no date is never kept, and only the thumbnails
/// of a picture's latest contents are.
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

        guard
            (try? data.write(to: fileURL, options: .atomic)) != nil,
            let prefix = fileNamePrefix(of: picture)
        else {
            return
        }

        let pictureKey = pictureKey(of: picture)
        removeThumbnails(where: { $0.hasPrefix(pictureKey) && !$0.hasPrefix(prefix) })
    }

    /// Removes the thumbnails of every picture but those named, as they are now, the other directories' included.
    ///
    /// Reads and removes off the caller's actor.
    ///
    /// - Parameter pictures: The pictures whose thumbnails stay.
    @concurrent
    func removeThumbnails(keeping pictures: Set<RecipePicture>) async {
        let prefixes = pictures.compactMap({ fileNamePrefix(of: $0) })
        removeThumbnails(where: { name in !prefixes.contains(where: { name.hasPrefix($0) }) })
    }

    private func removeThumbnails(where isRemoved: (String) -> Bool) {
        let path = folderURL.path(percentEncoded: false)

        guard let names = try? FileManager.default.contentsOfDirectory(atPath: path) else {
            return
        }

        for name in names where isRemoved(name) {
            try? FileManager.default.removeItem(at: folderURL.appending(path: name))
        }
    }

    /// Where a picture's thumbnail at a size is kept, or `nil` for a picture telling no date.
    private func fileURL(of picture: RecipePicture, filling pixelSize: CGSize) -> URL? {
        fileNamePrefix(of: picture).map { prefix in
            folderURL.appending(path: "\(prefix)\(Int(pixelSize.width.rounded()))x\(Int(pixelSize.height.rounded()))")
        }
    }

    /// What the names of a picture's thumbnails of its current contents start with, or `nil` for a picture telling no
    /// date.
    private func fileNamePrefix(of picture: RecipePicture) -> String? {
        picture.modificationDate.map { modificationDate in
            "\(pictureKey(of: picture))\(Self.digest(of: String(modificationDate.timeIntervalSinceReferenceDate)))-"
        }
    }

    // Hashed with the directory, so two directories' pictures at one path never share a thumbnail.
    private func pictureKey(of picture: RecipePicture) -> String {
        "\(Self.digest(of: "\(directoryPath)\n\(picture.id)"))-"
    }

    private static func digest(of text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).map({ String(format: "%02x", $0) }).joined()
    }
}
