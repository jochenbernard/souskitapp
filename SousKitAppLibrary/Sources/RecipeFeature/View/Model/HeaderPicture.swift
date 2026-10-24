import CoreGraphics

/// What the top of the recipe screen shows of the recipe's picture.
enum HeaderPicture {
    /// The header has not appeared yet, or the picture the recipe names is still being read.
    case reading

    /// A picture, read to fill the header.
    case read(CGImage)

    /// The recipe's placeholder, where it names no picture or its picture cannot be read.
    case placeholder
}
