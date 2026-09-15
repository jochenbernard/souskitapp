import SwiftUI

extension InsettableShape {
    func sousBorder() -> some View {
        strokeBorder(
            .separator.opacity(0.5),
            lineWidth: 1.0
        )
    }
}
