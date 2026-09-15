import SwiftUI

extension View {
    func sousButtonLabel(_ color: some ShapeStyle) -> some View {
        font(.body)
            .foregroundStyle(color)
            .padding(.horizontal, SousSpacing.xLarge)
            .padding(.vertical, SousSpacing.medium)
    }
}
