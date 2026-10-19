import CoreGraphics
import RecipeLibrary

struct KitchenFeaturePresenterStub: KitchenFeaturePresenterProtocol {
    func stackDidAppear() {}

    func didBecomeActive() {}

    func didPush(_: KitchenScreen, from _: KitchenScreen?) {}

    func didPop(toCount _: Int) {}

    func didChangeSearchText(_: String, in _: [String]) {}

    func didDismissCooking() {}

    func thumbnail(of _: RecipePicture, filling _: CGSize) -> CGImage? {
        nil
    }

    func lastThumbnail(of _: RecipePicture) -> CGImage? {
        nil
    }
}
