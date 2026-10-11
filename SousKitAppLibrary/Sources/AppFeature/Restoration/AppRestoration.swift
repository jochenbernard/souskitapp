import KitchenFeature

/// What the app has open, kept so a cold start opens it again.
struct AppRestoration: Hashable, Codable {
    /// What the kitchen has open, or `nil` while it stands on its recipe list.
    var kitchen: KitchenFeatureRestoration?

    /// Whether the settings are open.
    var isShowingSettings = false

    /// Whether nothing is open that a cold start would open again.
    var isEmpty: Bool {
        kitchen == nil && !isShowingSettings
    }
}
