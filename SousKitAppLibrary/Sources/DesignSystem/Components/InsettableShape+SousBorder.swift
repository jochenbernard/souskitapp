import SwiftUI

extension InsettableShape {
    /// Draws the border every surface shares, inside this shape.
    ///
    /// - Returns: The shape's border.
    public func sousBorder() -> some View {
        strokeBorder(
            .separator.opacity(0.5),
            lineWidth: 1.0
        )
    }
}
