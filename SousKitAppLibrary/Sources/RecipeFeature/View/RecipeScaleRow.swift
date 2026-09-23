import DesignSystem
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
            HStack(alignment: .firstTextBaseline, spacing: SousSpacing.medium) {
                Text("Scale", bundle: .module)

                Spacer(minLength: 0.0)

                value
            }
            .padding(.horizontal, SousSpacing.large)
            .padding(.vertical, SousSpacing.medium)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private var value: some View {
        HStack(spacing: SousSpacing.xSmall) {
            scale.text
                .multilineTextAlignment(.trailing)

            Image(systemName: "chevron.up.chevron.down")
                .imageScale(.small)
                .accessibilityHidden(true)
        }
        .foregroundStyle(.accent)
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
                .sousSurface(RoundedRectangle(cornerRadius: SousRadius.large))
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
