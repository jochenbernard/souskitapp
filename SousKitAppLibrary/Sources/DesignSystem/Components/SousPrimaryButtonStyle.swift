import SwiftUI

/// The one primary action on a screen: glass tinted in the accent, labelled in black.
///
/// A press flexes the glass and plays a haptic. The control keeps its size, since the
/// interactive glass already gives under the finger.
public struct SousPrimaryButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        ButtonPressBody(isPressed: configuration.isPressed) { isDown in
            let shape = Capsule()

            configuration.label
                .sousButtonLabel(.black)
                .glassEffect(.regular.tint(.accent).interactive(), in: shape)
                .contentShape(shape)
                .sensoryFeedback(trigger: isDown) { _, isDown in
                    isDown
                        ? .impact(flexibility: .rigid)
                        : .impact(flexibility: .rigid, intensity: ButtonPress.releaseIntensity)
                }
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
    Button("Boeuf Bourguignon") {}
        .buttonStyle(.sousPrimary)
        .padding(SousSpacing.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.groupedBackground)
}
