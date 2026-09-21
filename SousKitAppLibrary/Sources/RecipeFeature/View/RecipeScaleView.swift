import DesignSystem
import SousKit
import SwiftUI

/// The sheet that scales a recipe: one number, and what that number counts.
///
/// The sheet sits low, so the recipe above it stays in view and moves as the number is typed.
struct RecipeScaleView: View {
    private let presenter: RecipeFeaturePresenterProtocol
    private let scale: ScaleDisplay

    // What the sheet holds, measured as it is laid out, so a row of chips that wraps still fits.
    @State private var contentHeight: Double?

    // The toolbar and home indicator, which the sheet cannot measure before its detent applies.
    @ScaledMetric(relativeTo: .body) private var barHeight = 70.0

    // About as tall as the content comes out, for the one layout before it is measured.
    @ScaledMetric(relativeTo: .body) private var estimatedContentHeight = 200.0

    init(
        presenter: RecipeFeaturePresenterProtocol,
        scale: ScaleDisplay
    ) {
        self.presenter = presenter
        self.scale = scale
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(Text("Scale", bundle: .module))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        resetButton
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        doneButton
                    }
                }
        }
        .presentationDetents([.height(sheetHeight)])
        .presentationDragIndicator(.hidden)
    }

    private var sheetHeight: Double {
        (contentHeight ?? estimatedContentHeight) + barHeight
    }

    private var content: some View {
        VStack(spacing: SousSpacing.xLarge) {
            number

            targets
        }
        .sousPagePadding()
        .onGeometryChange(
            for: Double.self,
            of: { $0.size.height },
            action: { contentHeight = $0 }
        )
        // The sheet's own ground, so the page behind it is read through nothing but the sheet.
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .top
        )
        .sousPage()
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

    private var number: some View {
        VStack(spacing: SousSpacing.small) {
            scale.target.label
                .font(.subheadline)
                .foregroundStyle(.secondary)

            RecipeScaleNumber(
                presenter: presenter,
                target: scale.target,
                text: scale.text
            )

            follows
        }
    }

    /// The targets to choose between, which wrap where the recipe declares more than a row of them.
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

    /// What the number comes to on the recipe's other targets, which a cook reads rather than sets.
    @ViewBuilder
    private var follows: some View {
        if !scale.follows.isEmpty {
            HStack(spacing: SousSpacing.small) {
                ForEach(scale.follows, id: \.self) { follow in
                    if follow != scale.follows.first {
                        Text(verbatim: "·")
                    }

                    ScaleValueText(scale: follow)
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
private func previewScaleView(
    _ scale: RecipeScale,
    declaresServings: Bool = true
) -> RecipeScaleView {
    let source = declaresServings
        ? """
            ---
            title: Gratin Dauphinois
            servings: 6
            yield: [1.8 kg]
            ---

            Peel @{1.2 kg} potatoes@ and simmer them in @{500 ml} cream@.
            """
        : """
            ---
            title: Vinaigrette
            ---

            Whisk @{1 tsp} dijon mustard@ into @{2 tbsp} red wine vinegar@.
            """
    let parser = SousParser()
    let scaled = ScaledRecipe(
        asWritten: parser.parseRecipe(source).value,
        parser: parser,
        scale: scale
    )

    return RecipeScaleView(
        presenter: RecipeFeaturePresenterStub(),
        scale: ScaleDisplay(recipe: scaled, text: ScaleNumber.text(scaled.scale.value))
    )
}

#Preview("Scale sheet") {
    previewScaleView(RecipeScale(target: .servings, value: 12.0))
}

#Preview("Scale sheet, as written") {
    previewScaleView(RecipeScale(target: .servings, value: 6.0))
}

#Preview("Scale sheet, on a yield") {
    previewScaleView(RecipeScale(target: .yield(unit: "kg"), value: 3.6))
}

#Preview("Scale sheet, on the multiplier") {
    previewScaleView(RecipeScale(target: .multiplier, value: 0.5))
}

#Preview("Scale sheet, no servings declared") {
    previewScaleView(RecipeScale(target: .multiplier, value: 2.0), declaresServings: false)
}
