import DesignSystem
import RecipeScaling
import SousKit
import SwiftUI

/// A recipe's header on a surface: its facts, its tags and allergens, the lines left over, and
/// what the recipe is scaled to where the card offers a scale.
struct RecipeMetadataView: View {
    @LineContainerRadius private var radius

    private let presenter: RecipeFeaturePresenterProtocol
    private let metadata: MetadataDisplay
    private let scale: RecipeScale?
    private let header: RecipeHeaderView?

    /// - Parameters:
    ///   - scale: What the recipe is scaled to, or `nil` for a card that offers no scale.
    ///   - header: What the card opens with, or `nil` for the card alone.
    init(
        presenter: RecipeFeaturePresenterProtocol,
        metadata: MetadataDisplay,
        scale: RecipeScale?,
        header: RecipeHeaderView?
    ) {
        self.presenter = presenter
        self.metadata = metadata
        self.scale = scale
        self.header = header
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            header?
                .sousCardPicture(endsCard: metadata.isEmpty && scale == nil)

            factStrip

            labelsDivider

            labels

            ForEach(metadata.rows) { row in
                rowDivider(row)

                metadataRow(row)
            }

            scaleRow
        }
        // The header's picture takes the card's corners.
        .clipShape(.rect(cornerRadius: radius))
        .sousRowSurface()
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

    @ViewBuilder
    private func factTile(_ fact: MetadataFact) -> some View {
        if fact.kind == .servings {
            // A cook reaching for the servings to change them finds the scale sheet there too.
            Button(action: presenter.didTapScale) {
                factContent(fact)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        } else {
            factContent(fact)
        }
    }

    private func factContent(_ fact: MetadataFact) -> some View {
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
        .sousRowPadding()
    }

    @ViewBuilder
    private func metadataKey(_ row: MetadataRow) -> some View {
        if let knownKey = row.knownKey {
            Text(knownKey.label, bundle: .module)
        } else if !row.key.isEmpty {
            Text(verbatim: row.label)
        }
    }

    @ViewBuilder
    private var scaleRow: some View {
        if let scale {
            scaleDivider

            ScaleRow(
                Text("Scale", bundle: .module),
                scale: scale,
                action: presenter.didTapScale
            )
        }
    }

    /// The scale is the last row, so it is divided from anything the header put above it.
    @ViewBuilder
    private var scaleDivider: some View {
        if !metadata.isEmpty {
            Divider()
                .padding(.horizontal, SousSpacing.large)
        }
    }
}

@MainActor
private func previewMetadataView(
    _ header: String,
    scale: RecipeScale?
) -> RecipeMetadataView {
    RecipeMetadataView(
        presenter: RecipeFeaturePresenterStub(),
        metadata: RecipeDisplay.metadata(of: SousParser().parseRecipe(header).value.metadata),
        scale: scale,
        header: nil
    )
}

#Preview("Recipe metadata") {
    ScrollView {
        previewMetadataView(
            """
            ---
            title: Boeuf Bourguignon
            servings: 6
            prep-time: 30 min
            cook-time: 3 h
            tags: [dinner, classic, french]
            allergens: [gluten, dairy]
            ---
            """,
            scale: RecipeScale(target: .servings, value: 12.0)
        )
        .sousPagePadding()
    }
    .sousPage()
}

#Preview("Recipe metadata, with lines left over") {
    ScrollView {
        previewMetadataView(
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
            """,
            scale: RecipeScale(target: .servings, value: 6.0)
        )
        .sousPagePadding()
    }
    .sousPage()
}

#Preview("Recipe metadata, header of nothing but a title") {
    ScrollView {
        previewMetadataView(
            """
            ---
            title: Vinaigrette
            ---
            """,
            scale: RecipeScale(target: .multiplier, value: 1.0)
        )
        .sousPagePadding()
    }
    .sousPage()
}

#Preview("Recipe metadata, without the scale") {
    ScrollView {
        previewMetadataView(
            """
            ---
            title: Boeuf Bourguignon
            servings: 6
            prep-time: 30 min
            cook-time: 3 h
            tags: [dinner, classic, french]
            allergens: [gluten, dairy]
            ---
            """,
            scale: nil
        )
        .sousPagePadding()
    }
    .sousPage()
}
