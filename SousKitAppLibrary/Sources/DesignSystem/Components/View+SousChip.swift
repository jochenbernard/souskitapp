import SwiftUI

extension View {
    /// Draws this view as a chip, one of a set of short labels such as a recipe's tags.
    ///
    /// A set of chips takes ``SousFlowLayout``, so it wraps rather than running off the edge. A chip
    /// a cook chooses from a set is a button taking ``SousChipButtonStyle`` instead.
    ///
    /// - Returns: The view, as a chip.
    public func sousChip() -> some View {
        sousChip(filledWith: .tertiaryFill)
    }

    /// Draws this view as a chip on the fill given, so a chip label and a chip button share one shape.
    ///
    /// - Parameter fill: What the chip is filled with.
    /// - Returns: The view, as a chip.
    func sousChip(filledWith fill: some ShapeStyle) -> some View {
        font(.subheadline)
            .padding(.horizontal, SousSpacing.medium)
            .padding(.vertical, SousSpacing.xSmall)
            .background(fill, in: Capsule())
    }
}

#Preview("Chips") {
    SousFlowLayout(spacing: SousSpacing.small) {
        ForEach(["dinner", "classic", "french", "casserole", "frying pan"], id: \.self) { name in
            Text(verbatim: name)
                .sousChip()
        }
    }
    .frame(width: 240.0, alignment: .leading)
    .padding(SousSpacing.large)
    .sousRowSurface()
    .sousPagePadding()
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .topLeading
    )
    .sousPage()
}
