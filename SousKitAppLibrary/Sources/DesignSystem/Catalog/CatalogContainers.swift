import SwiftUI

struct CatalogContainers: View {
    // swiftlint:disable:next unused_declaration
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: SousSpacing.medium) {
            Text(verbatim: "Boeuf Bourguignon")
                .sousRow()

            rowGroup

            Text(verbatim: "This recipe could not be read")
                .sousCallout()

            loadingPlaceholder

            chips

            disclosureGroup
        }
    }

    private var rowGroup: some View {
        SousRowGroup {
            ForEach(["Crepes", "Gratin Dauphinois", "Madeleines"], id: \.self) { name in
                Text(verbatim: name)
                    .sousRowPadding()
            }
        }
    }

    private var loadingPlaceholder: some View {
        Text(verbatim: "Boeuf Bourguignon")
            .sousLoadingPlaceholder()
            .sousRow()
            .environment(\.isSousLoading, true)
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
