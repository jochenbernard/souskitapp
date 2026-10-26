import CoreGraphics
import Foundation
import RecipeLibrary
import Synchronization

/// The thumbnails kept for the pictures a kitchen shows first, read as soon as the recipes listed ahead of it land, and
/// each handed out once.
///
/// A class, so every copy of the repository holding it hands out the same ones. Releasing it gives up on the reads.
final class RecipeThumbnailReadAhead: Sendable {
    private struct State {
        var read: Task<Void, Never>?
        var thumbnails: [RecipePicture: CGImage] = [:]
    }

    private let state = Mutex(State())

    deinit {
        state.withLock({ $0.read?.cancel() })
    }

    /// Starts reading the thumbnails of the pictures a kitchen shows first once a listing lands, giving up on the reads
    /// started before.
    ///
    /// - Parameters:
    ///   - listing: The recipes listed ahead of the kitchen.
    ///   - cache: Where the thumbnails are kept.
    func start(after listing: Task<[ListedRecipe], Error>, from cache: RecipeThumbnailCache) {
        state.withLock { state in
            state.read?.cancel()
            state.thumbnails = [:]
            // Detached, so the thumbnails are ready even while the main actor is busy putting the first screen up.
            state.read = Task.detached(priority: .userInitiated) { [weak self] in
                let entries = (try? await listing.value)?.map(\.entry) ?? []
                // Read before the kitchen's screen is measured: the fewest it shows first, so it asks for every one.
                let pictures = RecipeListingOrder.firstPictures(of: entries, cardCount: 0)
                let thumbnails = await Self.read(pictures, from: cache)

                self?.state.withLock { state in
                    // Checked while held, so reads given up on never land over those started since.
                    if !Task.isCancelled {
                        state.thumbnails = thumbnails
                    }
                }
            }
        }
    }

    /// Hands out the thumbnail read ahead for a picture, once the reads are done.
    ///
    /// - Parameter picture: The picture, as the listing read ahead lists it.
    /// - Returns: The thumbnail, or `nil` where none was read for the picture or it was handed out before.
    func thumbnail(of picture: RecipePicture) async -> CGImage? {
        await state.withLock({ $0.read })?.value

        return state.withLock({ $0.thumbnails.removeValue(forKey: picture) })
    }

    private static func read(
        _ pictures: [RecipePicture],
        from cache: RecipeThumbnailCache
    ) async -> [RecipePicture: CGImage] {
        await withTaskGroup(of: (RecipePicture, CGImage?).self) { group in
            for picture in pictures {
                group.addTask {
                    (picture, Task.isCancelled ? nil : cache.smallestThumbnail(of: picture))
                }
            }

            return await group.reduce(into: [:], { $0[$1.0] = $1.1 })
        }
    }
}
