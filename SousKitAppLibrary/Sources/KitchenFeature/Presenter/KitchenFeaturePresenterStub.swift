import CoreGraphics
import RecipeLibrary

struct KitchenFeaturePresenterStub: KitchenFeaturePresenterProtocol {
    func stackDidAppear() {}

    func topScreenDidAppear() {}

    func didBecomeActive() {}

    func didPush(_: KitchenScreen, from _: KitchenScreen?) {}

    func didOpen(_: RecipeDocument) {}

    func didPop(toCount _: Int) {}

    func didChangeSearchText(_: String, in _: [String]) {}

    func screenDidAppear(_: KitchenScreen?) {}

    func didDismissCooking() {}

    func didPreview(_: RecipeEntry) {}

    func didChooseCooking(_: RecipeEntry, from _: KitchenScreen?) {}

    func didChooseScaling(_: RecipeEntry, from _: KitchenScreen?) {}

    func didChooseFolder(of _: RecipeEntry, from _: KitchenScreen?) {}

    func didChooseSearch(inFolderAt _: [String], from _: KitchenScreen?) {}

    func didChangeIsSearchPresented(_: Bool, in _: [String]) {}

    func pictureDidAppear(_: RecipePicture, filling _: CGSize) {}
}
