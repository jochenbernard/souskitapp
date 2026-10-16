import SwiftUI

/// A button drawn the way a toolbar draws one, as an icon on a circle of glass, for a bar or a list of the screen's
/// own.
///
/// The button's label shows as its icon alone, which follows the text size only as far as the circle fits it, and keeps
/// its title for VoiceOver.
struct GlassCircleButtonStyle: ButtonStyle {
    /// How wide and tall the button stands, a toolbar button's size.
    nonisolated static let diameter = 44.0

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(.iconOnly)
            .fontWeight(.medium)
            // Past this size the icon reaches the circle's edge.
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
            .frame(width: Self.diameter, height: Self.diameter)
            .contentShape(.circle)
            .glassEffect(.regular.interactive(), in: .circle)
    }
}

extension ButtonStyle where Self == GlassCircleButtonStyle {
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
