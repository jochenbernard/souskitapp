/// What a recipe screen has open, kept so a cold start opens the screen as it was left.
public struct RecipeFeatureRestoration: Sendable, Hashable, Codable {
    /// The scale a cook chose, or `nil` at the scale the file writes the recipe in.
    let scale: RecipeScale?

    /// Whether the scale sheet is open.
    let isScaling: Bool
}
