import SwiftUI

struct CatalogContainers: View {
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: SousSpacing.medium) {
            Text("Boeuf Bourguignon")
                .sousRow()

            Text("This recipe could not be read")
                .sousCallout()

            SousActivityNote {
                Text("Fetching from iCloud.")
            }

            chips

            disclosureGroup
        }
        .font(.body)
    }

    private var chips: some View {
        SousFlowLayout(spacing: SousSpacing.small) {
            ForEach(["dinner", "classic", "french"], id: \.self) { tag in
                Text(verbatim: tag)
                    .sousChip()
            }
        }
    }

    private var disclosureGroup: some View {
        DisclosureGroup("Gratin Dauphinois", isExpanded: $isExpanded) {
            Text("Rub a gratin dish with 1 clove garlic, butter it with 20 g butter, and heat the oven to 150C.")
                .sousRow()
        }
        .disclosureGroupStyle(.sous)
    }
}

#Preview("Containers") {
    CatalogContainers()
        .padding(SousSpacing.xLarge)
        .frame(maxHeight: .infinity)
        .background(.groupedBackground)
}
