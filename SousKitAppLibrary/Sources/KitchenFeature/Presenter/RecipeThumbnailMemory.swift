import CoreGraphics
import Foundation
import RecipeLibrary

/// The thumbnails the kitchen's cards read last, so a card scrolled back into view shows its picture at once.
///
/// A class, so every copy of the presenter keeps the same one. The thumbnails read longest ago go first once they
/// hold more than a budget of memory.
@MainActor
final class RecipeThumbnailMemory {
    private struct Key: Hashable {
        let id: String
        let modificationDate: Date?
    }

    private let byteBudget: Int

    private var thumbnails: [Key: CGImage] = [:]
    // Oldest first.
    private var order: [Key] = []
    private var byteCount = 0

    /// Creates a memory.
    ///
    /// - Parameter byteBudget: How many bytes of thumbnails it keeps at most.
    nonisolated init(byteBudget: Int = 48 * 1_024 * 1_024) {
        self.byteBudget = byteBudget
    }

    /// The thumbnail kept for a picture as it is now, at whatever size it was read.
    ///
    /// - Parameter picture: The picture.
    /// - Returns: The thumbnail, or `nil` where none is kept for the picture's current contents.
    func thumbnail(of picture: RecipePicture) -> CGImage? {
        thumbnails[Self.key(of: picture)]
    }

    /// Keeps a picture's thumbnail, in place of one kept for the picture before.
    ///
    /// - Parameters:
    ///   - thumbnail: The thumbnail.
    ///   - picture: The picture it was read from.
    func keep(_ thumbnail: CGImage, of picture: RecipePicture) {
        let key = Self.key(of: picture)
        forget(key)

        thumbnails[key] = thumbnail
        order.append(key)
        byteCount += Self.byteCount(of: thumbnail)

        while byteCount > byteBudget, let oldest = order.first, oldest != key {
            forget(oldest)
        }
    }

    private func forget(_ key: Key) {
        guard let thumbnail = thumbnails.removeValue(forKey: key) else {
            return
        }

        order.removeAll(where: { $0 == key })
        byteCount -= Self.byteCount(of: thumbnail)
    }

    // Availability is left out: a picture landing from iCloud shows what was read of it before.
    private static func key(of picture: RecipePicture) -> Key {
        Key(id: picture.id, modificationDate: picture.modificationDate)
    }

    private static func byteCount(of thumbnail: CGImage) -> Int {
        thumbnail.bytesPerRow * thumbnail.height
    }
}
