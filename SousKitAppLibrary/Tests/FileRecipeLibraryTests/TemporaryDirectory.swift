import CoreGraphics
@testable import FileRecipeLibrary
import Foundation
import ImageIO
import RecipeLibrary
import UniformTypeIdentifiers

/// A directory of its own under the temporary directory, removed when the suite holding it goes.
final class TemporaryDirectory: Sendable {
    /// Where the directory sits on disk.
    let url: URL

    /// Where the summaries of the directory's recipes are kept, beside the directory rather than in it.
    let summaryCacheURL: URL

    /// Where the thumbnails of the directory's pictures are kept, beside the directory rather than in it.
    let thumbnailCacheURL: URL

    /// Creates a directory, named for the suite and a fresh UUID so suites never share one.
    ///
    /// - Parameter name: The suite's name.
    /// - Throws: Whatever creating the directory throws.
    init(named name: String) throws {
        let directoryURL = URL(filePath: NSTemporaryDirectory())
            .appending(path: "\(name).\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        self.url = directoryURL
        self.summaryCacheURL = directoryURL.appendingPathExtension("RecipeSummaries.json")
        self.thumbnailCacheURL = directoryURL.appendingPathExtension("RecipeThumbnails")
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
        try? FileManager.default.removeItem(at: summaryCacheURL)
        try? FileManager.default.removeItem(at: thumbnailCacheURL)
    }

    /// The directory, as the library takes it.
    var recipeDirectory: RecipeDirectory {
        RecipeDirectory(url: url)
    }

    /// Writes an empty file into the directory.
    ///
    /// - Parameter fileName: The name to write it under.
    /// - Throws: Whatever writing the file throws.
    func writeFile(named fileName: String) throws {
        try Data().write(to: url.appending(path: fileName))
    }

    /// Writes a file holding `text`.
    ///
    /// - Parameters:
    ///   - fileName: The name to write it under.
    ///   - text: What the file holds.
    /// - Returns: The recipe the file is read as.
    /// - Throws: Whatever writing the file throws.
    @discardableResult
    func writeFile(named fileName: String, _ text: String) throws -> RecipeEntry {
        try Data(text.utf8).write(to: url.appending(path: fileName))

        return RecipeEntry(path: fileName, availability: .downloaded)
    }

    /// The cache keeping the summaries of the directory's recipes.
    var summaryCache: RecipeSummaryCache {
        RecipeSummaryCache(recipeDirectory: recipeDirectory, fileURL: summaryCacheURL)
    }

    /// Sets when a file's contents last changed.
    ///
    /// - Parameters:
    ///   - date: The date.
    ///   - fileName: The file's name inside the directory.
    /// - Throws: Whatever changing the file's attributes throws.
    func setModificationDate(_ date: Date, ofFileNamed fileName: String) throws {
        try FileManager.default.setAttributes(
            [.modificationDate: date],
            ofItemAtPath: url.appending(path: fileName).path(percentEncoded: false)
        )
    }

    /// Creates a directory inside this one.
    ///
    /// - Parameter name: The name to create it under.
    /// - Throws: Whatever creating the directory throws.
    func makeDirectory(named name: String) throws {
        try FileManager.default.createDirectory(
            at: url.appending(path: name),
            withIntermediateDirectories: true
        )
    }

    /// Writes a picture of one shade of gray as a PNG file.
    ///
    /// - Parameters:
    ///   - fileName: The name to write it under, inside the directory.
    ///   - width: The picture's width, in pixels.
    ///   - height: The picture's height, in pixels.
    ///   - gray: The shade, from 0 for black to 1 for white.
    /// - Throws: Whatever drawing or writing the picture throws.
    func writePicture(
        named fileName: String,
        width: Int,
        height: Int,
        gray: Double = 0.5
    ) throws {
        let image = try Self.picture(
            width: width,
            height: height,
            gray: gray
        )
        let fileURL = url.appending(path: fileName)

        let type = UTType.png.identifier as CFString

        guard
            let destination = CGImageDestinationCreateWithURL(
                fileURL as CFURL,
                type,
                1,
                nil
            )
        else {
            throw CocoaError(.fileWriteUnknown)
        }

        CGImageDestinationAddImage(
            destination,
            image,
            nil
        )

        guard CGImageDestinationFinalize(destination) else {
            throw CocoaError(.fileWriteUnknown)
        }
    }

    /// A picture of one shade of gray.
    static func picture(
        width: Int,
        height: Int,
        gray: Double
    ) throws -> CGImage {
        guard
            let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            )
        else {
            throw CocoaError(.fileWriteUnknown)
        }

        context.setFillColor(CGColor(gray: gray, alpha: 1.0))
        context.fill(
            CGRect(
                x: 0.0,
                y: 0.0,
                width: Double(width),
                height: Double(height)
            )
        )

        guard let image = context.makeImage() else {
            throw CocoaError(.fileWriteUnknown)
        }

        return image
    }
}
