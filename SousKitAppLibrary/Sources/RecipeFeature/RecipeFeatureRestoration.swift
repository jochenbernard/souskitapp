import RecipeScaling

/// How a recipe screen was left, kept so a cold start opens the screen as it was.
public struct RecipeFeatureRestoration: Sendable, Hashable, Codable {
    /// The scale a cook chose, or `nil` at the scale the recipe opens on.
    let scale: RecipeScale?
}
