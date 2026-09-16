import SwiftUI

extension View {
    /// Draws this view as a chip, one of a set of short labels such as a recipe's tags.
    ///
    /// A set of chips takes ``SousFlowLayout``, so it wraps rather than running off the edge.
    ///
    /// - Returns: The view, as a chip.
    public func sousChip() -> some View {
        font(.subheadline)
            .padding(.horizontal, SousSpacing.medium)
            .padding(.vertical, SousSpacing.xSmall)
            .background(.tertiaryFill, in: Capsule())
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
    .sousSurface(RoundedRectangle(cornerRadius: SousRadius.large))
    .sousPagePadding()
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .topLeading
    )
    .sousPage()
}
