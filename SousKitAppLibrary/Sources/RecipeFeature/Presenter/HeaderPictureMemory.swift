import RecipeLibrary

/// The picture the header's image was read from, so a picture listed later can be told apart from it.
///
/// A class, so every copy of the presenter keeps the same one.
@MainActor
final class HeaderPictureMemory {
    /// The picture the image the header shows was read from, or `nil` where it shows none.
    var picture: RecipePicture?

    nonisolated init() {}
}
