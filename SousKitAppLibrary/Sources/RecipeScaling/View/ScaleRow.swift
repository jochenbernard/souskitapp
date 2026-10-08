import DesignSystem
import SwiftUI

/// The row that reads the scale in force beside a title, and opens the scale sheet.
public struct ScaleRow: View {
    private let title: Text
    private let scale: RecipeScale
    private let action: @MainActor () -> Void

    /// Creates the row.
    ///
    /// - Parameters:
    ///   - title: What the row is called.
    ///   - scale: The scale in force.
    ///   - action: Opens the scale sheet.
    public init(
        _ title: Text,
        scale: RecipeScale,
        action: @escaping @MainActor () -> Void
    ) {
        self.title = title
        self.scale = scale
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            label
                .sousRowPadding()
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private var label: some View {
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
            ScaleRow(Text(verbatim: "Scale"), scale: scale, action: {})
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
