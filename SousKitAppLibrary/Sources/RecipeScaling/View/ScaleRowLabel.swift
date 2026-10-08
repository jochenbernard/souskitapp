import DesignSystem
import SwiftUI

/// What a row that opens the scale sheet reads: its title, and the scale in force.
public struct ScaleRowLabel: View {
    private let title: Text
    private let scale: RecipeScale

    /// Creates the label.
    ///
    /// - Parameters:
    ///   - title: What the row is called.
    ///   - scale: The scale in force.
    public init(_ title: Text, scale: RecipeScale) {
        self.title = title
        self.scale = scale
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: SousSpacing.medium) {
            title

            Spacer(minLength: 0.0)

            value
        }
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

#Preview("Scale row label") {
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
            ScaleRowLabel(Text(verbatim: "Scale"), scale: scale)
                .sousRow()
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
