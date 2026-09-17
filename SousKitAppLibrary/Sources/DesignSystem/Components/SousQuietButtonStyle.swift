import SwiftUI

/// A button of least emphasis, reading as a link.
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
    Button(action: {}, label: { Text(verbatim: "Vinaigrette") })
        .buttonStyle(.sousQuiet)
        .padding(SousSpacing.xLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.groupedBackground)
}
