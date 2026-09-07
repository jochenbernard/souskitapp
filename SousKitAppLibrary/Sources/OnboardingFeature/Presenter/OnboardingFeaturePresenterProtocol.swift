import Foundation

/// What ``OnboardingFeatureView`` reports to.
protocol OnboardingFeaturePresenterProtocol {
    @MainActor
    func didTapChooseDirectory()

    @MainActor
    func didChangeIsChoosingDirectory(_ isChoosing: Bool)

    @MainActor
    func didChooseDirectory(_ result: Result<URL, Error>)
}
