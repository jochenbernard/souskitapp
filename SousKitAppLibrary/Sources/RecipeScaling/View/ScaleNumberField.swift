import DesignSystem
import SwiftUI

/// The number a cook scales by, with a minus and a plus that step it.
///
/// The minus and the plus repeat while they are held, on the timing the system gives a stepper.
struct ScaleNumberField: View {
    private let presenter: ScaleSheetPresenterProtocol
    private let target: ScaleTarget
    private let text: String

    // Room to spare around a number at `.largeTitle`, growing with Dynamic Type.
    @ScaledMetric(relativeTo: .largeTitle) private var fieldWidth = 148.0

    // Six characters such as 156.25, which the field keeps while the minus and the plus shrink to fit beside it.
    @ScaledMetric(relativeTo: .largeTitle) private var minFieldWidth = 120.0

    // A target big enough to hit with a wet hand where the row has room, growing with Dynamic Type.
    @ScaledMetric(relativeTo: .title3) private var stepDiameter = 48.0

    init(
        presenter: ScaleSheetPresenterProtocol,
        target: ScaleTarget,
        text: String
    ) {
        self.presenter = presenter
        self.target = target
        self.text = text
    }

    var body: some View {
        ScaleNumberFieldLayout(spacing: SousSpacing.large) {
            stepButton(
                -1.0,
                systemImage: "minus",
                label: "Less"
            )
            .accessibilitySortPriority(2.0)

            field

            stepButton(
                1.0,
                systemImage: "plus",
                label: "More"
            )

            measuredNumber
        }
        // VoiceOver reads the minus, the field and the plus in that order, also where the field sits above them.
        .accessibilityElement(children: .contain)
    }

    private func stepButton(
        _ steps: Double,
        systemImage: String,
        label: LocalizedStringKey
    ) -> some View {
        Button(
            action: { presenter.didStepScale(by: steps) },
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
            text: Binding(get: { text }, set: { presenter.didChangeScaleText($0) }),
            prompt: nil,
            label: { target.label }
        )
        .labelsHidden()
        .keyboardType(.decimalPad)
        .multilineTextAlignment(.center)
        .font(.largeTitle)
        .monospacedDigit()
        // The layout keeps it to its ideal width in the row and stretches it across a line of its own.
        .frame(
            minWidth: minFieldWidth,
            idealWidth: fieldWidth,
            maxWidth: .infinity
        )
        .accessibilitySortPriority(1.0)
        .padding(.vertical, SousSpacing.small)
        .background(.tertiaryFill, in: RoundedRectangle(cornerRadius: SousRadius.medium))
    }

    // The number as wide as the field sets it, which tells the layout when the row would cut it off.
    private var measuredNumber: some View {
        Text(verbatim: text)
            .font(.largeTitle)
            .monospacedDigit()
            .hidden()
            .accessibilityHidden(true)
    }
}

#Preview("Scale number field") {
    VStack(spacing: SousSpacing.xLarge) {
        ScaleNumberField(
            presenter: ScaleSheetPresenterStub(),
            target: .servings,
            text: "12"
        )

        ScaleNumberField(
            presenter: ScaleSheetPresenterStub(),
            target: .multiplier,
            text: "2.5"
        )

        ScaleNumberField(
            presenter: ScaleSheetPresenterStub(),
            target: .yield(unit: "kg"),
            text: "3.6"
        )
    }
    .sousPagePadding()
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity
    )
    .sousPage()
}

#Preview("Scale number field, too long for its row") {
    ScaleNumberField(
        presenter: ScaleSheetPresenterStub(),
        target: .yield(unit: "ml"),
        text: "1406.25"
    )
    .sousPagePadding()
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity
    )
    .sousPage()
    .dynamicTypeSize(.accessibility5)
}
