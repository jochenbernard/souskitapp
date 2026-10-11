/// What ``AppFeatureView`` reports to.
protocol AppFeaturePresenterProtocol {
    @MainActor
    func didDismissSettings()
}
