import SwiftUI

/// One color chip in ``SousCatalog``, with its name and its use.
struct CatalogSwatch<Fill: ShapeStyle>: View {
    let fill: Fill
    let name: String
    let role: String

    var body: some View {
        HStack(spacing: SousSpacing.medium) {
            RoundedRectangle(cornerRadius: SousRadius.small)
                .fill(fill)
                .frame(width: 44.0, height: 44.0)
                .overlay {
                    RoundedRectangle(cornerRadius: SousRadius.small)
                        .strokeBorder(SousColor.border, lineWidth: 1.0)
                }

            VStack(alignment: .leading, spacing: SousSpacing.hairline) {
                Text(name)
                    .sousTextStyle(.data)
                    .foregroundStyle(SousColor.text)

                Text(role)
                    .sousTextStyle(.eyebrow)
                    .foregroundStyle(SousColor.textMuted)
            }

            Spacer(minLength: 0.0)
        }
    }
}

#Preview("Swatches") {
    VStack(alignment: .leading, spacing: SousSpacing.medium) {
        CatalogSwatch(
            fill: SousColor.accent,
            name: "accent",
            role: "live, here, do"
        )

        CatalogSwatch(
            fill: SousColor.surface,
            name: "surface",
            role: "cards and sheets"
        )

        CatalogSwatch(
            fill: SousPalette.flame,
            name: "Flame",
            role: "#F1541C"
        )
    }
    .padding(SousSpacing.xLarge)
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .topLeading
    )
    .background(SousColor.background)
}
