/// What ``AppFeatureView`` reports to.
protocol AppFeaturePresenterProtocol {
    @MainActor
    func didTapSettings()

    @MainActor
    func didDismissSettings()

    /// The app left the foreground.
    @MainActor
    func didEnterBackground()
}
