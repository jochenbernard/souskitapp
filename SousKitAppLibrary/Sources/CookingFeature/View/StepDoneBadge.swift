import DesignSystem
import SwiftUI

/// The check on a done step's number, drawn on as it appears.
struct StepDoneBadge: View {
    // Drawn off until the badge is on screen, so the check draws on as the badge fades in.
    @State private var isDrawn = false

    var body: some View {
        ZStack {
            Circle()
                .fill(.secondary)
                // Set off from the number it sits on by a ring of the row's own surface.
                .padding(SousSpacing.hairline)
                .background(.secondaryGroupedBackground, in: Circle())

            Image(systemName: "checkmark")
                .font(.caption2)
                .foregroundStyle(.secondaryGroupedBackground)
                .symbolEffect(.drawOff, isActive: !isDrawn)
                // The step's toggle already reads the step as done.
                .accessibilityHidden(true)
        }
        .onAppear {
            isDrawn = true
        }
    }
}

#Preview("Step done badge") {
    StepDoneBadge()
        .frame(width: 20.0, height: 20.0)
        .padding(SousSpacing.xLarge)
        .background(.secondaryGroupedBackground)
}
