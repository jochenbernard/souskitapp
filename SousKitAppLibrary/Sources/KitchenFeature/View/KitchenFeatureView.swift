import DesignSystem
import Foundation
import RecipeLibrary
import SwiftUI

struct KitchenFeatureView: View {
    private let viewModel: KitchenFeatureViewModel

    init(viewModel: KitchenFeatureViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SousSpacing.xLarge) {
                Text(verbatim: viewModel.recipeDirectory.name)
                    .sousTextStyle(.heading)
                    .foregroundStyle(SousColor.text)

                pathCard

                Text("Your recipes will be listed here.")
                    .sousTextStyle(.body)
                    .foregroundStyle(SousColor.textMuted)
            }
            .padding(SousSpacing.xLarge)
        }
        .background(SousColor.background)
    }

    /// The path, set in the mono face the scale gives metadata.
    private var pathCard: some View {
        Text(verbatim: viewModel.recipeDirectory.path)
            .sousTextStyle(.data)
            .foregroundStyle(SousColor.textMuted)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(SousSpacing.large)
            .background {
                let shape = RoundedRectangle(cornerRadius: SousRadius.large)

                shape
                    .fill(SousColor.surface)
                    .overlay {
                        shape.strokeBorder(SousColor.border, lineWidth: 1.0)
                    }
            }
    }
}

#Preview("Kitchen") {
    KitchenFeatureView(
        viewModel: KitchenFeatureViewModel(
            recipeDirectory: RecipeDirectory(url: URL(filePath: "/Users/cook/Documents/Recipes"))
        )
    )
}
