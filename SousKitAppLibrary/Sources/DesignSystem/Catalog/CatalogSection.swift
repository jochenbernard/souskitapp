import SwiftUI

/// A numbered block in ``SousCatalog``: an eyebrow, a title, and content on a surface.
struct CatalogSection<Content: View>: View {
    let number: String
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: SousSpacing.large) {
            Text(verbatim: "\(number) / \(title)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SousSpacing.xLarge)
        .sousSurface(RoundedRectangle(cornerRadius: SousRadius.large))
    }
}

#Preview("Section") {
    CatalogSection(number: "01", title: "Color") {
        Text("Rub a gratin dish with 1 clove garlic, butter it with 20 g butter, and heat the oven to 150C.")
            .font(.body)
    }
    .padding(SousSpacing.xLarge)
    .frame(maxHeight: .infinity)
    .background(.groupedBackground)
}
