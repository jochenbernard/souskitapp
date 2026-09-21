import SwiftUI

/// A chip a cook taps to choose it from a set, such as what a recipe is scaled by.
///
/// The chosen chip reads in the accent on ``SwiftUI/ShapeStyle/quaternaryAccentFill``, which is
/// Here on a chip. The rest read as ``SwiftUI/View/sousChip()`` does.
public struct SousChipButtonStyle: ButtonStyle {
    private let isSelected: Bool

    /// Creates the style.
    ///
    /// - Parameter isSelected: Whether this chip is the one chosen from its set.
    public init(isSelected: Bool) {
        self.isSelected = isSelected
    }

    public func makeBody(configuration: Configuration) -> some View {
        ButtonPressBody(isPressed: configuration.isPressed) { isDown in
            configuration.label
                .foregroundStyle(isSelected ? AnyShapeStyle(.accent) : AnyShapeStyle(.primary))
                .sousChip(
                    filledWith: isSelected ? AnyShapeStyle(.quaternaryAccentFill) : AnyShapeStyle(.tertiaryFill)
                )
                .contentShape(Capsule())
                .sousPressScale(isDown: isDown)
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

extension ButtonStyle where Self == SousChipButtonStyle {
    /// A chip chosen from a set. See ``SousChipButtonStyle``.
    ///
    /// - Parameter isSelected: Whether this chip is the one chosen from its set.
    /// - Returns: The style.
    public static func sousChip(isSelected: Bool) -> SousChipButtonStyle {
        SousChipButtonStyle(isSelected: isSelected)
    }
}

#Preview("Chip buttons") {
    @Previewable @State var chosen = "servings"

    SousFlowLayout(spacing: SousSpacing.small) {
        ForEach(["servings", "kg", "crepes"], id: \.self) { name in
            Button(action: { chosen = name }, label: { Text(verbatim: name) })
                .buttonStyle(.sousChip(isSelected: name == chosen))
        }
    }
    .padding(SousSpacing.xLarge)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.groupedBackground)
}
