import SwiftUI

/// The containers block of ``SousCatalog``: a row on a surface, a callout, and an activity note.
struct CatalogContainers: View {
    var body: some View {
        VStack(alignment: .leading, spacing: SousSpacing.medium) {
            Text("Boeuf Bourguignon")
                .foregroundStyle(SousColor.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, SousSpacing.large)
                .padding(.vertical, SousSpacing.medium)
                .sousSurface(Capsule())

            Text("This recipe could not be read")
                .sousCallout()

            SousActivityNote {
                Text("Fetching from iCloud.")
            }
        }
        .font(.body)
    }
}

#Preview("Containers") {
    CatalogContainers()
        .padding(SousSpacing.xLarge)
        .frame(maxHeight: .infinity)
        .background(SousColor.background)
}
