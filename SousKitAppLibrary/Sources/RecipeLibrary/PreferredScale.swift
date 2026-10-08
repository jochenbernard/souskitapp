/// How much of a recipe a recipe opens on, whatever its file writes.
public enum PreferredScale: Sendable, Hashable, Codable {
    /// A number of servings, for a recipe whose header declares servings; any other opens as written.
    case servings(Double)

    /// The recipe multiplied by a number, and counted the way it counts itself, such as in servings.
    case multiplier(Double)

    /// The recipe once, as its file writes it.
    public static let asWritten = Self.multiplier(1.0)
}
