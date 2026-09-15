/// Whether a recipe's contents are on the device.
public enum RecipeAvailability: Sendable, Hashable {
    /// The contents are on the device, and reading the recipe returns them at once.
    case downloaded

    /// The contents are on their way to the device.
    case downloading

    /// The contents are kept elsewhere, and reading the recipe fetches them first.
    case notDownloaded
}
