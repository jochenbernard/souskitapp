@testable import AppFeature
import Foundation
import Testing

extension AppFeaturePresenterTests {
    private var vinaigretteURL: URL {
        URL.temporaryDirectory.appending(path: "vinaigrette.sous")
    }

    @Test("a file opened on onboarding leaves onboarding up until a folder is picked")
    func fileOnOnboarding() {
        let presenter = launch()

        presenter.didOpenFile(at: vinaigretteURL)

        #expect(presenter.viewModel?.screen.identity == .onboarding)
    }

    @Test("a file opened with the settings open closes them, for the recipe to open on the kitchen")
    func fileClosesSettings() {
        let presenter = launch()
        presenter.onboardingFeatureDidChooseMockRecipes()
        presenter.didTapSettings()

        presenter.didOpenFile(at: vinaigretteURL)

        #expect(presenter.viewModel?.openSettings == nil)
    }

    @Test("a link to anything but a file opens nothing")
    func linkOpensNothing() throws {
        let presenter = launch()
        presenter.onboardingFeatureDidChooseMockRecipes()
        presenter.didTapSettings()

        presenter.didOpenFile(at: try #require(URL(string: "https://example.com/vinaigrette.sous")))

        #expect(presenter.viewModel?.openSettings != nil)
    }
}
