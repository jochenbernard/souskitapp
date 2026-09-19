import SwiftUI

/// Every button on a screen but the primary one.
public struct SousSecondaryButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        ButtonPressBody(isPressed: configuration.isPressed) { isDown in
            let shape = Capsule()

            configuration.label
                .sousButtonLabel(.primary)
                .background {
                    shape
                        .fill(.tertiaryFill)
                        .overlay {
                            shape.sousBorder()
                        }
                }
                .contentShape(shape)
                .sousPressScale(isDown: isDown)
        }
    }
}

extension ButtonStyle where Self == SousSecondaryButtonStyle {
    /// Every button on a screen but the primary one. See ``SousSecondaryButtonStyle``.
    public static var sousSecondary: SousSecondaryButtonStyle {
        SousSecondaryButtonStyle()
    }
}

#Preview("Secondary button") {
    Button(action: {}, label: { Text(verbatim: "Gratin Dauphinois") })
        .buttonStyle(.sousSecondary)
        .padding(SousSpacing.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.groupedBackground)
}
