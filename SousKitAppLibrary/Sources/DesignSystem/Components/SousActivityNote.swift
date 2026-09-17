import SwiftUI

/// What a screen is waiting on.
public struct SousActivityNote<Label: View>: View {
    private let label: Label

    /// Creates a note.
    ///
    /// - Parameter label: What the screen is waiting on.
    public init(@ViewBuilder label: () -> Label) {
        self.label = label()
    }

    public var body: some View {
        HStack(spacing: SousSpacing.medium) {
            // The accent means live, and work still running is what it is for.
            ProgressView()
                .tint(.accent)

            label
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, SousSpacing.small)
    }
}

#Preview("Activity note") {
    SousActivityNote {
        Text(verbatim: "Fetching from iCloud.")
    }
    .padding(SousSpacing.xLarge)
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .topLeading
    )
    .background(.groupedBackground)
}
