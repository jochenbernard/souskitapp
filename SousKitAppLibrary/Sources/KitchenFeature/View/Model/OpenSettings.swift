import Foundation
import SettingsFeature

/// The settings over the kitchen's recipe list.
///
/// Built each time the settings open, so every visit reads what is remembered now, and identified by that visit, so
/// the sheet keeps what it shows while it slides away.
struct OpenSettings: Identifiable {
    let id = UUID()
    let feature: SettingsFeature

    /// Whether the settings open again as a cold start found them, rather than from the button that opens them.
    let isRestored: Bool
}
