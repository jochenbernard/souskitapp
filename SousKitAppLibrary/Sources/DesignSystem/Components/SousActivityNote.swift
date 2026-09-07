import SwiftUI

/// A spinner beside a label, for what a screen is waiting on.
public struct SousActivityNote<Label: View>: View {
    @Environment(\.colorScheme) private var colorScheme

    private let label: Label

    /// Creates a note.
    ///
    /// - Parameter label: What the screen is waiting on, set in ``SousColor/textMuted``.
    public init(@ViewBuilder label: () -> Label) {
        self.label = label()
    }

    public var body: some View {
        HStack(spacing: SousSpacing.medium) {
            // Orange means live, and work still running is what the accent is for.
            ProgressView()
                .tint(SousColor.accent.color(in: colorScheme))

            label
                .foregroundStyle(SousColor.textMuted)
        }
    }
}

#Preview("Activity note") {
    SousActivityNote {
        Text("Fetching from iCloud.")
            .sousTextStyle(.body)
    }
    .padding(SousSpacing.xLarge)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(SousColor.background)
}
