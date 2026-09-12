import SwiftUI

extension View {
    /// Sets this button label in the control's box: the body line, in a color, inside the padding.
    ///
    /// The line box is included: without it the control sits under the 44pt minimum target.
    ///
    /// - Parameter color: The style the label is drawn in.
    /// - Returns: The label, in the control's box.
    func sousButtonLabel(_ color: some ShapeStyle) -> some View {
        sousTextBlock(.body)
            .foregroundStyle(color)
            .padding(.horizontal, SousSpacing.xLarge)
            .padding(.vertical, SousSpacing.medium)
    }
}
