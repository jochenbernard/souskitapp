import SwiftUI

/// A button drawn the way a toolbar draws one, as an icon on a circle of glass, for a bar or a list of the screen's
/// own.
///
/// The button's label shows as its icon alone, which keeps one size at every text size as a toolbar's does, and keeps
/// its title for VoiceOver. Held at an accessibility text size, the button shows its icon and title enlarged, as a
/// toolbar's does, and is pressed as the finger lifts from it.
struct GlassCircleButtonStyle: PrimitiveButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    /// How wide and tall the button stands, a toolbar button's size.
    nonisolated static let diameter = 44.0

    func makeBody(configuration: Configuration) -> some View {
        Button(configuration)
            .buttonStyle(GlassCircleButtonFace())
            .accessibilityShowsLargeContentViewer {
                // A close button's own label shows as its title alone unless asked for both.
                configuration.label
                    .labelStyle(.titleAndIcon)
            }
            // The enlarged label takes the touch from the button, which is then pressed here instead.
            .gesture(
                LargeContentRelease(
                    size: CGSize(width: Self.diameter, height: Self.diameter),
                    isEnabled: isEnabled,
                    action: configuration.trigger
                )
            )
    }
}

extension PrimitiveButtonStyle where Self == GlassCircleButtonStyle {
    /// A button drawn as an icon on a circle of glass. See ``GlassCircleButtonStyle``.
    static var glassCircle: GlassCircleButtonStyle {
        GlassCircleButtonStyle()
    }
}

#Preview("Glass circle buttons") {
    HStack {
        Button(role: .close, action: {})
            .buttonStyle(.glassCircle)

        Button(action: {}, label: { Label("Collapse timers", systemImage: "chevron.down") })
            .buttonStyle(.glassCircle)
    }
    .padding()
}
