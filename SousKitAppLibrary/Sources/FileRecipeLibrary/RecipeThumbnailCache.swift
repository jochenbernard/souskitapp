import CoreGraphics
import CryptoKit
import Foundation
import ImageIO
import RecipeLibrary
import Synchronization
import UniformTypeIdentifiers

/// The thumbnails of one directory's pictures, kept between launches in a folder the system may clear.
///
/// A thumbnail is found by its picture's path, the picture's modification date, and the kept size holding the box it
/// fills, so a picture replaced in the directory is never shown as it was, and a box resized a little reads the
/// thumbnail kept before. A picture telling no date is never kept, and only the thumbnails of a picture's latest
/// contents are, at the two kept sizes kept last.
struct RecipeThumbnailCache: Sendable {
    private static let jpegQuality = 0.85
    // Four sizes to an octave: a box growing by up to a fifth reads the same thumbnail.
    private static let sizesPerOctave = 4.0

    // By folder: how often it was cleared, so a cache made before keeps nothing there again.
    private static let clearCounts = Mutex<[URL: Int]>([:])

    private let clearCount: Int
    private let directoryPath: String
    private let folderURL: URL

    /// Creates a cache.
    ///
    /// - Parameters:
    ///   - recipeDirectory: The directory whose pictures are kept.
    ///   - folderURL: Where the thumbnails are kept, outside the directory.
    init(recipeDirectory: RecipeDirectory, folderURL: URL) {
        self.clearCount = Self.clearCounts.withLock({ $0[folderURL, default: 0] })
        self.directoryPath = recipeDirectory.url.standardizedFileURL.path(percentEncoded: false)
        self.folderURL = folderURL
    }

    /// The box a thumbnail is made and kept for, holding a box it is read for.
    ///
    /// - Parameter pixelSize: The box, in pixels.
    /// - Returns: The smallest of a few sizes holding the box, in pixels.
    static func keptSize(holding pixelSize: CGSize) -> CGSize {
        CGSize(width: keptLength(holding: pixelSize.width), height: keptLength(holding: pixelSize.height))
    }

    /// Removes every thumbnail kept in a folder, leaving every cache made for it before keeping nothing there.
    ///
    /// - Parameter folderURL: The folder.
    static func clear(folderURL: URL) {
        // Held while removing, so a thumbnail already being written lands first.
        clearCounts.withLock { clearCounts in
            clearCounts[folderURL, default: 0] += 1
            try? FileManager.default.removeItem(at: folderURL)
        }
    }

    /// The thumbnail kept for a picture as it is now, scaled down to fill a box.
    ///
    /// - Parameters:
    ///   - picture: The picture.
    ///   - pixelSize: The box, in pixels.
    /// - Returns: The thumbnail, decoded, or `nil` where none is kept at the kept size holding the box.
    func thumbnail(of picture: RecipePicture, filling pixelSize: CGSize) -> CGImage? {
        guard let fileURL = fileURL(of: picture, filling: pixelSize) else {
            return nil
        }

        // Scaled to the box, not shown scaled, which would blur it.
        return try? RecipeThumbnailMaker.thumbnail(ofImageAt: fileURL, filling: pixelSize)
    }

    /// The thumbnail kept for a picture as it is now at the largest kept size, for a box not known yet.
    ///
    /// - Parameter picture: The picture.
    /// - Returns: The thumbnail, decoded, or `nil` where none is kept.
    func largestThumbnail(of picture: RecipePicture) -> CGImage? {
        guard let prefix = fileNamePrefix(of: picture) else {
            return nil
        }

        let keptFiles = names().compactMap { name in
            Self.keptSize(inFileName: name, after: prefix).map({ (name: name, size: $0) })
        }

        guard
            let largest = keptFiles.max(by: { $0.size.width * $0.size.height < $1.size.width * $1.size.height })
        else {
            return nil
        }

        return try? RecipeThumbnailMaker.thumbnail(
            ofImageAt: folderURL.appending(path: largest.name),
            filling: largest.size
        )
    }

    /// Keeps a picture's thumbnail made to fill the kept size holding a box.
    ///
    /// A thumbnail that cannot be written is made again the next time, so a failure is dropped.
    ///
    /// - Parameters:
    ///   - thumbnail: The thumbnail.
    ///   - picture: The picture it was made from.
    ///   - pixelSize: The box, in pixels.
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

        guard
            write(data as Data, to: fileURL),
            let prefix = fileNamePrefix(of: picture)
        else {
            return
        }

        let pictureKey = pictureKey(of: picture)
        removeThumbnails(where: { $0.hasPrefix(pictureKey) && !$0.hasPrefix(prefix) })
        removeThumbnails(at: otherSizes(of: prefix, than: fileURL).dropFirst())
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

    /// Writes a thumbnail, unless the folder was cleared since the cache was made.
    private func write(_ data: Data, to fileURL: URL) -> Bool {
        // Held while writing, so a clear meanwhile never has the folder written into again.
        Self.clearCounts.withLock { clearCounts in
            guard clearCounts[folderURL, default: 0] == clearCount else {
                return false
            }

            try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)

            return (try? data.write(to: fileURL, options: .atomic)) != nil
        }
    }

    private func removeThumbnails(where isRemoved: (String) -> Bool) {
        removeThumbnails(at: names().filter(isRemoved).map({ folderURL.appending(path: $0) }))
    }

    private func removeThumbnails(at urls: some Sequence<URL>) {
        for url in urls {
            try? FileManager.default.removeItem(at: url)
        }
    }

    /// A picture's thumbnails of its current contents at other sizes than one, kept last first.
    private func otherSizes(of prefix: String, than fileURL: URL) -> [URL] {
        names()
            .filter({ $0.hasPrefix(prefix) && $0 != fileURL.lastPathComponent })
            .map({ folderURL.appending(path: $0) })
            .sorted(by: { Self.modificationDate(of: $0) > Self.modificationDate(of: $1) })
    }

    private func names() -> [String] {
        (try? FileManager.default.contentsOfDirectory(atPath: folderURL.path(percentEncoded: false))) ?? []
    }

    /// Where a picture's thumbnail for a box is kept, or `nil` for a picture telling no date.
    private func fileURL(of picture: RecipePicture, filling pixelSize: CGSize) -> URL? {
        let keptSize = Self.keptSize(holding: pixelSize)

        return fileNamePrefix(of: picture).map { prefix in
            folderURL.appending(path: "\(prefix)\(Int(keptSize.width))x\(Int(keptSize.height))")
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

    /// The kept size a thumbnail's file is named for, or `nil` where the name does not start with a prefix.
    private static func keptSize(inFileName name: String, after prefix: String) -> CGSize? {
        guard name.hasPrefix(prefix) else {
            return nil
        }

        let lengths = name.dropFirst(prefix.count).split(separator: "x").compactMap({ Double($0) })

        guard lengths.count == 2 else {
            return nil
        }

        return CGSize(width: lengths[0], height: lengths[1])
    }

    private static func keptLength(holding length: Double) -> Double {
        // The step below the length, then up to the first that holds it, as each step is rounded to a whole pixel.
        var step = (log2(max(length, 1.0)) * sizesPerOctave).rounded(.down)

        while pow(2.0, step / sizesPerOctave).rounded() < length {
            step += 1.0
        }

        return pow(2.0, step / sizesPerOctave).rounded()
    }

    private static func modificationDate(of url: URL) -> Date {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
    }

    private static func digest(of text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).map({ String(format: "%02x", $0) }).joined()
    }
}
