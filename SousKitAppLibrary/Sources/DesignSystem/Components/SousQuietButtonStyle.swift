import SwiftUI

/// A button with no surface and no border, reading as a link.
///
/// A press scales the control and changes no color.
public struct SousQuietButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        ButtonPressBody(isPressed: configuration.isPressed) { isDown in
            configuration.label
                .sousButtonLabel(.accent)
                .contentShape(Capsule())
                .sousPressScale(isDown: isDown)
        }
    }
}

extension ButtonStyle where Self == SousQuietButtonStyle {
    /// A button reading as a link. See ``SousQuietButtonStyle``.
    public static var sousQuiet: SousQuietButtonStyle {
        SousQuietButtonStyle()
    }
}

#Preview("Quiet button") {
    Button("Vinaigrette") {}
        .buttonStyle(.sousQuiet)
        .padding(SousSpacing.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.groupedBackground)
}
