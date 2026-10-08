/// The ``SettingsExit`` waiting on the settings sheet to finish sliding away.
@MainActor
final class PendingSettingsExit {
    var exit: SettingsExit?

    nonisolated init() {}
}
