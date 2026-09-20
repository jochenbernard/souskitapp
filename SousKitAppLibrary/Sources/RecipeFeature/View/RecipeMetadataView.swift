import DesignSystem
import SousKit
import SwiftUI

/// A recipe's header on a surface: its facts, its tags and allergens, and the lines left over.
struct RecipeMetadataView: View {
    private let metadata: MetadataDisplay

    init(metadata: MetadataDisplay) {
        self.metadata = metadata
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            factStrip

            labelsDivider

            labels

            ForEach(metadata.rows) { row in
                rowDivider(row)

                metadataRow(row)
            }
        }
        .sousSurface(RoundedRectangle(cornerRadius: SousRadius.large))
    }

    private var hasLabels: Bool {
        !metadata.tags.isEmpty || !metadata.allergens.isEmpty
    }

    @ViewBuilder
    private var factStrip: some View {
        if !metadata.facts.isEmpty {
            HStack(spacing: 0.0) {
                ForEach(metadata.facts) { fact in
                    factDivider(fact)

                    factTile(fact)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, SousSpacing.medium)
        }
    }

    @ViewBuilder
    private func factDivider(_ fact: MetadataFact) -> some View {
        if fact.id != metadata.facts.first?.id {
            Divider()
        }
    }

    private func factTile(_ fact: MetadataFact) -> some View {
        VStack(spacing: SousSpacing.xSmall) {
            Image(systemName: fact.kind.systemImage)
                .foregroundStyle(.secondary)

            Text(verbatim: fact.value)

            Text(fact.kind.label, bundle: .module)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(fact.kind.label, bundle: .module))
        .accessibilityValue(Text(verbatim: fact.value))
    }

    @ViewBuilder
    private var labelsDivider: some View {
        if !metadata.facts.isEmpty, hasLabels {
            Divider()
        }
    }

    @ViewBuilder
    private var labels: some View {
        if hasLabels {
            VStack(alignment: .leading, spacing: SousSpacing.medium) {
                tagChips

                allergenNote
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(SousSpacing.large)
        }
    }

    @ViewBuilder
    private var tagChips: some View {
        if !metadata.tags.isEmpty {
            SousFlowLayout(spacing: SousSpacing.small) {
                ForEach(metadata.tags.indices, id: \.self) { index in
                    Text(verbatim: metadata.tags[index])
                        .sousChip()
                }
            }
        }
    }

    @ViewBuilder
    private var allergenNote: some View {
        if !metadata.allergens.isEmpty {
            Label(
                title: { Text("Contains \(RecipeDisplay.joinedList(metadata.allergens))", bundle: .module) },
                icon: { Image(systemName: "allergens") }
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func rowDivider(_ row: MetadataRow) -> some View {
        if row.id != metadata.rows.first?.id || !metadata.facts.isEmpty || hasLabels {
            Divider()
                .padding(.horizontal, SousSpacing.large)
        }
    }

    private func metadataRow(_ row: MetadataRow) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: SousSpacing.medium) {
            metadataKey(row)

            Spacer(minLength: 0.0)

            Text(verbatim: row.value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, SousSpacing.large)
        .padding(.vertical, SousSpacing.medium)
    }

    @ViewBuilder
    private func metadataKey(_ row: MetadataRow) -> some View {
        if let knownKey = row.knownKey {
            Text(knownKey.label, bundle: .module)
        } else if !row.key.isEmpty {
            Text(verbatim: row.label)
        }
    }
}

private func previewMetadata(_ header: String) -> MetadataDisplay {
    RecipeDisplay.metadata(of: SousParser().parseRecipe(header).value.metadata)
}

#Preview("Recipe metadata") {
    ScrollView {
        RecipeMetadataView(
            metadata: previewMetadata(
                """
                ---
                title: Boeuf Bourguignon
                servings: 6
                prep-time: 30 min
                cook-time: 3 h
                tags: [dinner, classic, french]
                allergens: [gluten, dairy]
                ---
                """
            )
        )
        .sousPagePadding()
    }
    .sousPage()
}

#Preview("Recipe metadata, with lines left over") {
    ScrollView {
        RecipeMetadataView(
            metadata: previewMetadata(
                """
                ---
                title: Gratin Dauphinois
                language: en
                version: 1.0
                servings: 6
                yield: [1.8 kg]
                tags: [comfort food, french, make-ahead]
                diet: [vegetarian]
                allergens: [dairy]
                source: https://example.com/gratin-dauphinois
                author: Jean Dupont
                license: CC-BY-4.0
                image: images/gratin-dauphinois.jpg
                prep-time: 30 min
                cook-time: 1 h 30 min
                make-ahead: best assembled a day ahead and baked from cold
                nutrition:
                  calories: 3300 kcal
                  protein: 44 g
                ---
                """
            )
        )
        .sousPagePadding()
    }
    .sousPage()
}
