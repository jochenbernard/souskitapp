import SwiftUI

struct CatalogContainers: View {
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: SousSpacing.medium) {
            Text(verbatim: "Boeuf Bourguignon")
                .sousRow()

            Text(verbatim: "This recipe could not be read")
                .sousCallout()

            SousActivityNote {
                Text(verbatim: "Fetching from iCloud.")
            }

            chips

            disclosureGroup
        }
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
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: { gratinStep.sousRow() },
            label: { Text(verbatim: "Gratin Dauphinois") }
        )
        .disclosureGroupStyle(.sous)
    }

    private var gratinStep: Text {
        Text(verbatim: "Rub a gratin dish with 1 clove garlic, butter it with 20 g butter, and heat the oven to 150C.")
    }
}

#Preview("Containers") {
    CatalogContainers()
        .padding(SousSpacing.xLarge)
        .frame(maxHeight: .infinity)
        .background(.groupedBackground)
}
