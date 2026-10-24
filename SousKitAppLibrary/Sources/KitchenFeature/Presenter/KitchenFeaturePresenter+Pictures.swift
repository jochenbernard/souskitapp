import CoreGraphics
import RecipeLibrary

extension KitchenFeaturePresenter {
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
            thumbnailMemory.forget(picture)
        }
    }
}
