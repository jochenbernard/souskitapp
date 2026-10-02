import SwiftUI

/// A button drawn the way a toolbar draws one, as an icon on a circle of glass, for a bar or a list of the screen's
/// own.
///
/// The button's label shows as its icon alone, and keeps its title for VoiceOver.
struct GlassCircleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(.iconOnly)
            .fontWeight(.medium)
            // A toolbar button's size.
            .frame(width: 44.0, height: 44.0)
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
