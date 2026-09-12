import SwiftUI

/// Every button on a screen but the primary one: the surface token inside a border.
///
/// A press scales the control and changes no color.
public struct SousSecondaryButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        ButtonPressBody(isPressed: configuration.isPressed) { isDown in
            let shape = Capsule()

            configuration.label
                .sousButtonLabel(SousColor.text)
                .background {
                    shape
                        .fill(SousColor.surface)
                        .overlay {
                            shape.strokeBorder(SousColor.border, lineWidth: 1.0)
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
    Button("Gratin Dauphinois") {}
        .buttonStyle(.sousSecondary)
        .padding(SousSpacing.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SousColor.background)
}
