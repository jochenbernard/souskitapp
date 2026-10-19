import Foundation

/// The picture a recipe's header names, as its repository finds it.
public struct RecipePicture: Sendable, Hashable {
    /// What the repository finds the picture by, which no two of its pictures share.
    public let id: String

    /// When the picture last changed, or `nil` where the repository cannot tell.
    public let modificationDate: Date?

    /// Whether the picture's contents are on the device.
    public let availability: RecipeAvailability

    /// Creates a picture.
    ///
    /// - Parameters:
    ///   - id: What the repository finds the picture by.
    ///   - modificationDate: When the picture last changed, or `nil` where the repository cannot tell.
    ///   - availability: Whether the picture's contents are on the device.
    public init(
        id: String,
        modificationDate: Date?,
        availability: RecipeAvailability
    ) {
        self.id = id
        self.modificationDate = modificationDate
        self.availability = availability
    }
}
