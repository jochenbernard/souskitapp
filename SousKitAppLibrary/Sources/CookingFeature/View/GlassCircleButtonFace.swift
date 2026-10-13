import SwiftUI

/// How a glass circle button looks: its label's icon alone, on a circle of glass. See ``GlassCircleButtonStyle``.
struct GlassCircleButtonFace: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(.iconOnly)
            .fontWeight(.medium)
            // The circle does not grow with the text, so neither does the icon.
            .dynamicTypeSize(.large)
            .frame(width: GlassCircleButtonStyle.diameter, height: GlassCircleButtonStyle.diameter)
            .contentShape(.circle)
            .glassEffect(.regular.interactive(), in: .circle)
    }
}

#Preview("Glass circle button face") {
    Button(action: {}, label: { Label("Collapse timers", systemImage: "chevron.down") })
        .buttonStyle(GlassCircleButtonFace())
        .padding()
}
