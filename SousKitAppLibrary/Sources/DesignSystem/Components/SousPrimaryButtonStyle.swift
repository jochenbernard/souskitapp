import SwiftUI

/// The one primary action on a screen.
public struct SousPrimaryButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        ButtonPressBody(isPressed: configuration.isPressed) { isDown in
            let shape = Capsule()

            configuration.label
                .sousButtonLabel(.white)
                // No press scale: the interactive glass already gives under the finger.
                .glassEffect(.regular.tint(.accent).interactive(), in: shape)
                .contentShape(shape)
                .sousPressFeedback(isDown: isDown)
        }
    }
}

extension ButtonStyle where Self == SousPrimaryButtonStyle {
    /// The one primary action on a screen. See ``SousPrimaryButtonStyle``.
    public static var sousPrimary: SousPrimaryButtonStyle {
        SousPrimaryButtonStyle()
    }
}

#Preview("Primary button") {
    Button(action: {}, label: { Text(verbatim: "Boeuf Bourguignon") })
        .buttonStyle(.sousPrimary)
        .padding(SousSpacing.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.groupedBackground)
}
