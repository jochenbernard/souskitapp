import SwiftUI

struct CatalogContainers: View {
    var body: some View {
        VStack(alignment: .leading, spacing: SousSpacing.medium) {
            Text("Boeuf Bourguignon")
                .sousRow()

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
        .background(.groupedBackground)
}
