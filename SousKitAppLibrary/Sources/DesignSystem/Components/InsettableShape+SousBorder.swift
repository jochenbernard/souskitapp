import SwiftUI

extension InsettableShape {
    /// The hairline edge of a surface, a secondary button, or a swatch: `separator` at half opacity.
    ///
    /// - Returns: The border, inset to sit inside the shape.
    func sousBorder() -> some View {
        strokeBorder(
            .separator.opacity(0.5),
            lineWidth: 1.0
        )
    }
}
