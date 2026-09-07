/// Whether a recipe file's contents are on the device.
public enum RecipeFileAvailability: Sendable, Hashable {
    /// The contents are on the device, and opening the file reads them at once.
    case downloaded

    /// The contents are being fetched from iCloud.
    case downloading

    /// The contents are in iCloud, and opening the file fetches them first.
    case notDownloaded
}
