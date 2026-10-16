import SwiftUI

/// A number a cook sets, under what it counts, with a minus and a plus either side of it.
///
/// The minus and the plus repeat while they are held, on the timing the system gives a stepper.
public struct SousNumberField: View {
    private let label: Text
    private let prompt: Text?
    private let onStep: @MainActor (Double) -> Void

    @Binding private var text: String

    // Room to spare around a number at `.largeTitle`, growing with Dynamic Type.
    @ScaledMetric(relativeTo: .largeTitle) private var fieldWidth = 148.0

    // Six characters such as 156.25, which the field keeps while the minus and the plus shrink to fit beside it.
    @ScaledMetric(relativeTo: .largeTitle) private var minFieldWidth = 120.0

    // A target big enough to hit with a wet hand where the row has room, growing with Dynamic Type.
    @ScaledMetric(relativeTo: .title3) private var stepDiameter = 48.0

    /// Creates a field.
    ///
    /// - Parameters:
    ///   - label: What the number counts.
    ///   - text: What the field holds, which is not a number until it is typed out.
    ///   - prompt: What an empty field shows, or `nil` for what the number counts.
    ///   - onStep: Reports how many steps a tap beside the number takes, which is -1 for the minus and 1 for the plus.
    public init(
        _ label: Text,
        text: Binding<String>,
        prompt: Text? = nil,
        onStep: @escaping @MainActor (Double) -> Void
    ) {
        self.label = label
        self._text = text
        self.prompt = prompt
        self.onStep = onStep
    }

    public var body: some View {
        VStack(spacing: SousSpacing.small) {
            label
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: SousSpacing.large) {
                stepButton(
                    -1.0,
                    systemImage: "minus",
                    label: "Less"
                )

                field

                stepButton(
                    1.0,
                    systemImage: "plus",
                    label: "More"
                )
            }
        }
    }

    private func stepButton(
        _ steps: Double,
        systemImage: String,
        label: LocalizedStringKey
    ) -> some View {
        Button(
            action: { onStep(steps) },
            label: {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(.accent)
                    .frame(
                        idealWidth: stepDiameter,
                        maxWidth: stepDiameter,
                        idealHeight: stepDiameter,
                        maxHeight: stepDiameter
                    )
                    .aspectRatio(1.0, contentMode: .fit)
                    // As tall as it is wide whatever height it is offered, so a sheet short of room does not shrink it.
                    .fixedSize(horizontal: false, vertical: true)
                    .background(.tertiaryFill, in: Circle())
            }
        )
        .buttonStyle(.plain)
        .buttonRepeatBehavior(.enabled)
        .accessibilityLabel(Text(label, bundle: .module))
        .layoutPriority(1.0)
    }

    private var field: some View {
        TextField(
            text: $text,
            prompt: prompt,
            label: { label }
        )
        .labelsHidden()
        .keyboardType(.decimalPad)
        .multilineTextAlignment(.center)
        .font(.largeTitle)
        .monospacedDigit()
        .frame(
            minWidth: minFieldWidth,
            idealWidth: fieldWidth,
            maxWidth: fieldWidth
        )
        .padding(.vertical, SousSpacing.small)
        .background(.tertiaryFill, in: RoundedRectangle(cornerRadius: SousRadius.medium))
    }
}

#Preview("Number field") {
    @Previewable @State var text = "12"

    SousNumberField(
        Text(verbatim: "Servings"),
        text: $text,
        onStep: { text = String((Int(text) ?? 0) + Int($0)) }
    )
    .sousPagePadding()
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity
    )
    .sousPage()
}
