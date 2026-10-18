import DesignSystem
import SwiftUI

/// A key of the new timer sheet's keypad, big enough to hit with a messy finger.
struct NewTimerKey<Label: View>: View {
    @Environment(\.isEnabled) private var isEnabled

    private let action: () -> Void
    private let label: Label

    // A target well past the 44pt minimum, growing with Dynamic Type.
    @ScaledMetric(relativeTo: .title) private var height = 60.0

    init(
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button(action: action) {
            label
                .font(.title)
                .monospacedDigit()
                .foregroundStyle(isEnabled ? .primary : .tertiary)
                .frame(maxWidth: .infinity, minHeight: height)
                .background(.tertiaryFill, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.sousBare)
    }
}

#Preview("New timer keys") {
    HStack(spacing: SousSpacing.medium) {
        NewTimerKey(action: {}, label: { Text(verbatim: "5") })

        NewTimerKey(action: {}, label: { Text(verbatim: "00") })

        NewTimerKey(action: {}, label: { Image(systemName: "delete.backward") })
            .disabled(true)
    }
    .sousPagePadding()
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity
    )
    .sousPage()
}
