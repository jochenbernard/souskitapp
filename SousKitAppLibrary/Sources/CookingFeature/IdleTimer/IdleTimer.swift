/// Whether the device dims and locks the screen once it sits idle.
public protocol IdleTimer: Sendable {
    /// Keeps the screen on, or lets it dim and lock again once the device sits idle.
    ///
    /// - Parameter isDisabled: Whether the screen stays on.
    @MainActor
    func setDisabled(_ isDisabled: Bool)
}
