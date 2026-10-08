import DesignSystem
import SwiftUI

/// The number a cook scales by, with a minus and a plus either side of it.
///
/// The minus and the plus repeat while they are held, on the timing the system gives a stepper.
struct ScaleNumberField: View {
    private let presenter: ScaleSheetPresenterProtocol
    private let target: ScaleTarget
    private let text: String

    // Wide enough for four digits at `.largeTitle`, growing with Dynamic Type.
    @ScaledMetric(relativeTo: .largeTitle) private var fieldWidth = 148.0

    // A target big enough to hit with a wet hand, growing with Dynamic Type.
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
                    .frame(width: stepDiameter, height: stepDiameter)
                    .background(.tertiaryFill, in: Circle())
            }
        )
        .buttonStyle(.plain)
        .buttonRepeatBehavior(.enabled)
        .accessibilityLabel(Text(label, bundle: .module))
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
        .frame(width: fieldWidth)
        .padding(.vertical, SousSpacing.small)
        .background(.tertiaryFill, in: RoundedRectangle(cornerRadius: SousRadius.medium))
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
