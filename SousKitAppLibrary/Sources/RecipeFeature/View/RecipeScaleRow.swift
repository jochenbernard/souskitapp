import DesignSystem
import RecipeScaling
import SwiftUI

/// The row on the header card that reads how much of the recipe to make, and opens the scale sheet.
struct RecipeScaleRow: View {
    private let presenter: RecipeFeaturePresenterProtocol
    private let scale: RecipeScale

    init(
        presenter: RecipeFeaturePresenterProtocol,
        scale: RecipeScale
    ) {
        self.presenter = presenter
        self.scale = scale
    }

    var body: some View {
        Button(action: presenter.didTapScale) {
            ScaleRowLabel(Text("Scale", bundle: .module), scale: scale)
                .sousRowPadding()
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

#Preview("Scale row") {
    VStack(spacing: SousSpacing.medium) {
        ForEach(
            [
                RecipeScale(target: .servings, value: 6.0),
                RecipeScale(target: .servings, value: 1.0),
                RecipeScale(target: .yield(unit: "kg"), value: 3.6),
                RecipeScale(target: .multiplier, value: 1.0)
            ],
            id: \.self
        ) { scale in
            RecipeScaleRow(presenter: RecipeFeaturePresenterStub(), scale: scale)
                .sousRowSurface()
        }
    }
    .sousPagePadding()
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .topLeading
    )
    .sousPage()
}
