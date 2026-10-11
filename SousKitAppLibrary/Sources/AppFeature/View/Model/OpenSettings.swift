import Foundation
import SettingsFeature

/// The settings over the app's screen.
///
/// Identified by the visit rather than the feature, so the sheet keeps what it shows while it slides away, and stays
/// up when the settings are built again for another repository.
struct OpenSettings: Identifiable {
    let id: UUID
    let feature: SettingsFeature

    /// Whether the settings open again as a cold start found them, rather than from the button that opens them.
    let isRestored: Bool
}
