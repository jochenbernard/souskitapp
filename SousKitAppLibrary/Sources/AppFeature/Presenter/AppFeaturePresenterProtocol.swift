/// What ``AppFeatureView`` reports to.
protocol AppFeaturePresenterProtocol {
    /// The view is on screen.
    @MainActor
    func viewDidAppear()

    @MainActor
    func didTapSettings()

    @MainActor
    func didDismissSettings()

    /// The app left the foreground.
    @MainActor
    func didEnterBackground()
}
