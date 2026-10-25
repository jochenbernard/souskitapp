import Foundation

/// What ``AppFeatureView`` reports to.
protocol AppFeaturePresenterProtocol {
    /// The view is on screen.
    @MainActor
    func viewDidAppear()

    @MainActor
    func didTapSettings()

    @MainActor
    func didDismissSettings()

    /// A file was handed to the app to open, such as a recipe tapped in the Files app.
    ///
    /// - Parameter url: The file.
    @MainActor
    func didOpenFile(at url: URL)

    /// The app left the foreground.
    @MainActor
    func didEnterBackground()
}
