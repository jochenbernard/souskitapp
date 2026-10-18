import DesignSystem
import SwiftUI

/// The sheet that sets a scale: one number, and what that number counts.
///
/// The sheet sits low, so what it scales stays in view above it and moves as the number is typed.
public struct ScaleSheet: View {
    private let title: Text
    private let presenter: ScaleSheetPresenterProtocol
    private let scale: ScaleDisplay

    /// Creates the sheet.
    ///
    /// - Parameters:
    ///   - title: What the sheet is called.
    ///   - presenter: What the sheet reports to.
    ///   - scale: What the sheet has on it.
    public init(
        _ title: Text,
        presenter: ScaleSheetPresenterProtocol,
        scale: ScaleDisplay
    ) {
        self.title = title
        self.presenter = presenter
        self.scale = scale
    }

    public var body: some View {
        SousSheet(
            title,
            content: {
                number

                targets
            },
            actions: {
                ToolbarItem(placement: .topBarLeading) {
                    resetButton
                }

                ToolbarItem(placement: .confirmationAction) {
                    doneButton
                }
            }
        )
    }

    private var number: some View {
        VStack(spacing: SousSpacing.small) {
            scale.target.label
                .font(.subheadline)
                .foregroundStyle(.secondary)
                // The number field carries it as its own name.
                .accessibilityHidden(true)

            ScaleNumberField(
                presenter: presenter,
                target: scale.target,
                text: scale.text
            )

            follows
        }
    }

    /// The targets to choose between, which wrap where there are more than a row of them.
    @ViewBuilder
    private var targets: some View {
        if !scale.targets.isEmpty {
            SousFlowLayout(spacing: SousSpacing.small) {
                ForEach(scale.targets, id: \.self) { target in
                    targetChip(target)
                }
            }
        }
    }

    private var resetButton: some View {
        Button(action: presenter.didTapReset) {
            Label(
                title: { Text("Reset", bundle: .module) },
                icon: { Image(systemName: "arrow.counterclockwise") }
            )
        }
        .disabled(scale.isDefault)
    }

    private var doneButton: some View {
        Button(role: .confirm, action: { presenter.didChangeIsScaling(false) })
    }

    /// What the number comes to on the other targets, which a cook reads rather than sets.
    @ViewBuilder
    private var follows: some View {
        if !scale.follows.isEmpty {
            HStack(spacing: SousSpacing.small) {
                ForEach(scale.follows, id: \.self) { follow in
                    if follow != scale.follows.first {
                        Text(verbatim: "·")
                    }

                    follow.text
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private func targetChip(_ target: ScaleTarget) -> some View {
        Button(
            action: { presenter.didTapTarget(target) },
            label: { target.name }
        )
        .buttonStyle(.sousChip(isSelected: target == scale.target))
    }
}

@MainActor
private func previewScaleSheet(_ scale: ScaleDisplay) -> ScaleSheet {
    ScaleSheet(
        Text(verbatim: "Scale"),
        presenter: ScaleSheetPresenterStub(),
        scale: scale
    )
}

#Preview("Scale sheet") {
    previewScaleSheet(
        ScaleDisplay(
            target: .servings,
            text: "12",
            targets: [.servings, .yield(unit: "kg"), .multiplier],
            follows: [
                RecipeScale(target: .yield(unit: "kg"), value: 3.6),
                RecipeScale(target: .multiplier, value: 2.0)
            ],
            isDefault: false
        )
    )
}

#Preview("Scale sheet, at its default") {
    previewScaleSheet(
        ScaleDisplay(
            target: .servings,
            text: "6",
            targets: [.servings, .yield(unit: "kg"), .multiplier],
            follows: [
                RecipeScale(target: .yield(unit: "kg"), value: 1.8),
                RecipeScale(target: .multiplier, value: 1.0)
            ],
            isDefault: true
        )
    )
}

#Preview("Scale sheet, one target") {
    previewScaleSheet(
        ScaleDisplay(
            target: .multiplier,
            text: "2",
            targets: [],
            follows: [],
            isDefault: false
        )
    )
}
