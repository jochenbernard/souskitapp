import SwiftUI

/// A button its label draws in full, such as a mark the cook ticks, felt as the primary button is.
public struct SousBareButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        ButtonPressBody(isPressed: configuration.isPressed) { isDown in
            configuration.label
                .sousPressScale(isDown: isDown)
                .sousPressFeedback(isDown: isDown)
        }
    }
}

extension ButtonStyle where Self == SousBareButtonStyle {
    /// A button its label draws in full. See ``SousBareButtonStyle``.
    public static var sousBare: SousBareButtonStyle {
        SousBareButtonStyle()
    }
}

#Preview("Bare button") {
    Button(
        action: {},
        label: {
            Text(verbatim: "1")
                .monospacedDigit()
                .frame(width: 32.0, height: 32.0)
                .background(.tertiaryFill, in: Circle())
        }
    )
    .buttonStyle(.sousBare)
    .padding(SousSpacing.xLarge)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.groupedBackground)
}
