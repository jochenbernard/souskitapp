import SwiftUI

/// One color chip in ``SousCatalog``, with its name and its use.
struct CatalogSwatch: View {
    let fill: Color
    let name: String
    let role: String

    var body: some View {
        HStack(spacing: SousSpacing.medium) {
            RoundedRectangle(cornerRadius: SousRadius.small)
                .fill(fill)
                .frame(width: 44.0, height: 44.0)
                .overlay {
                    RoundedRectangle(cornerRadius: SousRadius.small)
                        .strokeBorder(
                            .separator.opacity(0.5),
                            lineWidth: 1.0
                        )
                }

            VStack(alignment: .leading, spacing: SousSpacing.hairline) {
                Text(name)
                    .font(.subheadline)

                Text(role)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0.0)
        }
    }
}

#Preview("Swatches") {
    VStack(alignment: .leading, spacing: SousSpacing.medium) {
        CatalogSwatch(
            fill: .accent,
            name: "accent",
            role: "live, here, do"
        )

        CatalogSwatch(
            fill: .quaternaryAccentFill,
            name: "quaternaryAccentFill",
            role: "callouts"
        )

        CatalogSwatch(
            fill: .secondaryGroupedBackground,
            name: "secondaryGroupedBackground",
            role: "rows and cards"
        )
    }
    .padding(SousSpacing.xLarge)
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .topLeading
    )
    .background(.groupedBackground)
}
