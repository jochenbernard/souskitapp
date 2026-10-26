import CoreGraphics
import RecipeLibrary

extension KitchenFeaturePresenter {
    // About the first two screens of cards on an iPhone.
    private static let cachedPictureCount = 24
    // The longest the cards wait for them, many times what reading kept thumbnails takes.
    private static let cachedThumbnailWait = Duration.milliseconds(300)

    @MainActor
    func pictureDidAppear(_ picture: RecipePicture, filling pixelSize: CGSize) async {
        guard !thumbnailMemory.holdsThumbnail(of: picture, filling: pixelSize) else {
            return
        }

        let thumbnail = try? await recipeRepository.readThumbnail(of: picture, filling: pixelSize)

        // A card scrolled away or resized meanwhile reads again, so a read for a smaller box never lands over a larger.
        guard !Task.isCancelled else {
            return
        }

        if let thumbnail {
            thumbnailMemory.keep(thumbnail, of: picture)
        } else {
            thumbnailMemory.readDidFail(of: picture)
        }
    }

    /// Keeps the thumbnails the repository holds for the pictures a folder shows first, those read within a moment,
    /// so its cards show them from their first frame.
    @MainActor
    func keepCachedThumbnails(in folder: KitchenFolder) async {
        let cards = folder.folders.flatMap(\.stackedCards) + folder.cards
        let pictures = Array(cards.lazy.compactMap(\.recipeEntry.picture).prefix(Self.cachedPictureCount))
        let (thumbnails, continuation) = AsyncStream.makeStream(of: (RecipePicture, CGImage?).self)

        for picture in pictures {
            Task { [recipeRepository] in
                continuation.yield((picture, await recipeRepository.cachedThumbnail(of: picture)))
            }
        }

        // Ends the wait on reads that take too long, which carry on unheard.
        let deadline = Task {
            try? await Task.sleep(for: Self.cachedThumbnailWait)
            continuation.finish()
        }

        for await (picture, thumbnail) in thumbnails.prefix(pictures.count) {
            if let thumbnail {
                thumbnailMemory.keep(thumbnail, of: picture)
            }
        }

        deadline.cancel()
    }
}
