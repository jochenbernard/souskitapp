import CoreGraphics
import RecipeLibrary

/// The thumbnails the kitchen's cards read last, written to what the cards show, so a card scrolled back into view
/// shows its picture at once.
///
/// A class, so every copy of the presenter keeps the same one. One thumbnail per picture, the one read last, so a
/// picture replaced is shown as it was only until it is read again. The thumbnails read longest ago go first once
/// they hold more than a budget of memory.
@MainActor
final class RecipeThumbnailMemory {
    private struct Kept {
        let thumbnail: CGImage
        let picture: RecipePicture
    }

    private let byteBudget: Int
    private let shownThumbnails: KitchenThumbnails

    // By picture id.
    private var kept: [String: Kept] = [:]
    // Picture ids, oldest first.
    private var order: [String] = []
    private var byteCount = 0

    /// Creates a memory.
    ///
    /// - Parameters:
    ///   - shownThumbnails: What the cards show, which holds every thumbnail kept and none other.
    ///   - byteBudget: How many bytes of thumbnails it keeps at most.
    nonisolated init(shownThumbnails: KitchenThumbnails, byteBudget: Int = 48 * 1_024 * 1_024) {
        self.shownThumbnails = shownThumbnails
        self.byteBudget = byteBudget
    }

    /// Whether a thumbnail is kept for a picture as it is now that fills a box, which one read for a larger box does
    /// as sharply.
    ///
    /// - Parameters:
    ///   - picture: The picture.
    ///   - pixelSize: The box, in pixels.
    /// - Returns: Whether one is kept for the picture's current contents, which a picture telling no date never has.
    func holdsThumbnail(of picture: RecipePicture, filling pixelSize: CGSize) -> Bool {
        guard
            picture.modificationDate != nil,
            let entry = kept[picture.id],
            entry.picture.modificationDate == picture.modificationDate
        else {
            return false
        }

        return Double(entry.thumbnail.width) >= pixelSize.width && Double(entry.thumbnail.height) >= pixelSize.height
    }

    /// Keeps a picture's thumbnail, in place of the one kept for the picture before.
    ///
    /// - Parameters:
    ///   - thumbnail: The thumbnail.
    ///   - picture: The picture it was read from.
    func keep(_ thumbnail: CGImage, of picture: RecipePicture) {
        forget(picture)

        kept[picture.id] = Kept(thumbnail: thumbnail, picture: picture)
        order.append(picture.id)
        byteCount += Self.byteCount(of: thumbnail)
        shownThumbnails[picture] = thumbnail

        while byteCount > byteBudget, let oldest = order.first.flatMap({ kept[$0] }), oldest.picture.id != picture.id {
            forget(oldest.picture)
        }
    }

    /// Lets go of the thumbnail kept for a picture, whatever its contents were then.
    ///
    /// - Parameter picture: The picture.
    func forget(_ picture: RecipePicture) {
        guard let removed = kept.removeValue(forKey: picture.id) else {
            return
        }

        order.removeAll(where: { $0 == picture.id })
        byteCount -= Self.byteCount(of: removed.thumbnail)
        shownThumbnails[picture] = nil
    }

    /// Lets go of the thumbnail kept for a picture whose read failed, and notes the failure for its card.
    ///
    /// - Parameter picture: The picture.
    func readDidFail(of picture: RecipePicture) {
        forget(picture)
        shownThumbnails.readDidFail(of: picture)
    }

    private static func byteCount(of thumbnail: CGImage) -> Int {
        thumbnail.bytesPerRow * thumbnail.height
    }
}
