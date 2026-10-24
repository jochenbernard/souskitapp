@testable import KitchenFeature
import RecipeLibrary
import Testing

extension KitchenFeatureRestorationTests {
    @MainActor
    @Test("a kitchen restored zooms none of the screens it opens again, as no card opened them")
    func restoredScreensDoNotZoom() async {
        let gratin = RecipeEntry.stubbed(at: "French/Comfort food/gratin-dauphinois")
        let restoration = KitchenFeatureRestoration(folderPath: ["French", "Comfort food"], recipeID: gratin.id)

        let kitchen = await restore(restoration, listing: [.success([gratin])])

        #expect(kitchen.viewModel.pushedScreens.count == 3)
        #expect(kitchen.viewModel.zoomSources.isEmpty)
    }
}
