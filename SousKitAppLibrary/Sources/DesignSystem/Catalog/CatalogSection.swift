import SwiftUI

/// A numbered block in ``SousCatalog``: an eyebrow, a title, and content on a surface.
struct CatalogSection<Content: View>: View {
    let number: String
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: SousSpacing.large) {
            Text(verbatim: "\(number) / \(title)")
                .sousTextStyle(.eyebrow)
                .foregroundStyle(SousColor.textMuted)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SousSpacing.xLarge)
        .background {
            RoundedRectangle(cornerRadius: SousRadius.large, style: .continuous)
                .fill(SousColor.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: SousRadius.large, style: .continuous)
                        .strokeBorder(SousColor.border, lineWidth: 1.0)
                }
        }
    }
}

#Preview("Section") {
    CatalogSection(number: "01", title: "Color") {
        Text("Rub a gratin dish with 1 clove garlic, butter it with 20 g butter, and heat the oven to 150C.")
            .sousTextStyle(.body)
            .foregroundStyle(SousColor.text)
    }
    .padding(SousSpacing.xLarge)
    .frame(maxHeight: .infinity)
    .background(SousColor.background)
}
