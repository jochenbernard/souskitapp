import DesignSystem
import RecipeLibrary
import SousKit
import SwiftUI

/// A parsed recipe: the header and what it takes, then what to do, side by side where the width allows.
struct RecipeBodyView: View {
    private let presenter: RecipeFeaturePresenterProtocol
    private let recipe: ScaledRecipe
    private let metadata: MetadataDisplay
    private let expandedSections: Set<RecipeSection>

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // The overview's width beside the steps, growing with Dynamic Type.
    @ScaledMetric(relativeTo: .body) private var overviewWidth = 360.0

    // A `.subheadline` number with room around it, growing with Dynamic Type.
    @ScaledMetric(relativeTo: .subheadline) private var stepNumberDiameter = 26.0

    init(
        presenter: RecipeFeaturePresenterProtocol,
        recipe: ScaledRecipe,
        metadata: MetadataDisplay,
        expandedSections: Set<RecipeSection>
    ) {
        self.presenter = presenter
        self.recipe = recipe
        self.metadata = metadata
        self.expandedSections = expandedSections
    }

    var body: some View {
        columns {
            overview

            stepSection
        }
    }

    private var isSideBySide: Bool {
        horizontalSizeClass == .regular
    }

    // One layout either way, so a change of size class keeps the sections rather than rebuilding them.
    private var columns: AnyLayout {
        isSideBySide
            ? AnyLayout(HStackLayout(alignment: .top, spacing: SousSpacing.xxLarge))
            : AnyLayout(VStackLayout(alignment: .leading, spacing: SousSpacing.xxLarge))
    }

    @ViewBuilder
    private var overview: some View {
        let ingredientList = RecipeDisplay.ingredientList(of: recipe.scaled)
        let cookwareNames = RecipeDisplay.cookwareNames(of: recipe.scaled)

        // The header card carries the scale, so it stands even where the file writes no header.
        VStack(alignment: .leading, spacing: SousSpacing.xxLarge) {
            metadataView

            ingredientSection(ingredientList)

            cookwareSection(cookwareNames)
        }
        .frame(maxWidth: isSideBySide ? overviewWidth : .infinity)
    }

    @ViewBuilder
    private var stepSection: some View {
        if !recipe.scaled.steps.isEmpty {
            VStack(alignment: .leading, spacing: SousSpacing.xLarge) {
                ForEach(StepNumbering.numberedGroups(of: recipe.scaled)) { numbered in
                    groupView(numbered)
                }
            }
        }
    }

    private var metadataView: some View {
        RecipeMetadataView(
            presenter: presenter,
            metadata: metadata,
            scale: recipe.scale
        )
    }

    @ViewBuilder
    private func ingredientSection(_ ingredientList: IngredientList) -> some View {
        if !ingredientList.rows.isEmpty {
            section(.ingredients) {
                VStack(alignment: .leading, spacing: SousSpacing.small) {
                    ingredientRows(ingredientList.rows)

                    stapleNote(ingredientList.staples)
                }
            }
        }
    }

    @ViewBuilder
    private func cookwareSection(_ names: [String]) -> some View {
        if !names.isEmpty {
            section(.cookware) {
                surface {
                    SousFlowLayout(spacing: SousSpacing.small) {
                        ForEach(names, id: \.self) { name in
                            Text(verbatim: name)
                                .sousChip()
                        }
                    }
                }
            }
        }
    }

    private func groupView(_ numbered: NumberedGroup) -> some View {
        VStack(alignment: .leading, spacing: SousSpacing.small) {
            groupName(numbered.group)

            stepRows(numbered)
        }
    }

    private func section(
        _ section: RecipeSection,
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        DisclosureGroup(
            isExpanded: isExpanded(section),
            content: content,
            label: { Text(section.label, bundle: .module) }
        )
        .disclosureGroupStyle(.sous)
    }

    private func ingredientRows(_ rows: [IngredientRow]) -> some View {
        SousRowGroup {
            ForEach(rows, id: \.name) { row in
                ingredientRow(row)
            }
        }
    }

    @ViewBuilder
    private func stapleNote(_ staples: [String]) -> some View {
        if !staples.isEmpty {
            Text("Plus \(RecipeDisplay.joinedList(staples)) from the pantry.", bundle: .module)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, SousSpacing.large)
        }
    }

    private func surface(@ViewBuilder content: () -> some View) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(SousSpacing.large)
            .sousSurface(RoundedRectangle(cornerRadius: SousRadius.large))
    }

    @ViewBuilder
    private func groupName(_ group: StepGroup) -> some View {
        if let name = group.name {
            Text(verbatim: name)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, SousSpacing.large)
        }
    }

    private func stepRows(_ numbered: NumberedGroup) -> some View {
        SousRowGroup {
            ForEach(numbered.numberedSteps, id: \.number) { number, step in
                stepView(step, number: number)
            }
        }
    }

    private func ingredientRow(_ row: IngredientRow) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: SousSpacing.medium) {
            Text(verbatim: row.name)

            Spacer(minLength: 0.0)

            amountText(row.amount)
        }
        .padding(.horizontal, SousSpacing.large)
        .padding(.vertical, SousSpacing.medium)
    }

    private func stepView(_ step: Step, number: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: SousSpacing.medium) {
            stepNumber(number)

            stepProse(step)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        // The number is the row's tallest line, so padding it evenly sets it as far from the top as from the side.
        .padding(SousSpacing.large)
    }

    @ViewBuilder
    private func amountText(_ amount: String?) -> some View {
        if let amount {
            Text(verbatim: amount)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func stepNumber(_ number: Int) -> some View {
        Text(verbatim: String(number))
            .font(.subheadline)
            .monospacedDigit()
            .frame(width: stepNumberDiameter, height: stepNumberDiameter)
            .background(.tertiaryFill, in: Circle())
    }

    private func stepProse(_ step: Step) -> Text {
        Text(StepProse.attributedProse(of: step, annotationColor: .accent))
    }

    private func isExpanded(_ section: RecipeSection) -> Binding<Bool> {
        Binding(
            get: { expandedSections.contains(section) },
            set: { presenter.didChangeIsExpanded($0, of: section) }
        )
    }
}

private func previewRecipe(scale: RecipeScale? = nil) -> ScaledRecipe {
    let parser = SousParser()
    let recipe = parser.parseRecipe(
        """
        ---
        title: Brioche
        servings: 10
        yield: [1 loaf]
        prep-time: 40 min
        cook-time: 55 min
        tags: [baking, classic, french]
        allergens: [gluten, dairy, eggs]
        ---

        Mix @{500 g} flour@, @{60 g} caster sugar@, @{10 g} salt@:staple, and
        @{=10 g} yeast@ in a #mixing bowl#, add @{6} eggs@ and @{60 ml} milk@, and work
        the dough until it pulls away clean.

        Beat @{250 g} butter@ in a piece at a time, then bring the dough together and
        refrigerate it ~overnight~ (or up to ~2 days~).

        The next day, shape it into a #loaf tin# buttered with @{10 g} butter@, prove it
        until puffy, about ~2-3 h~, then bake at 180C for ~45-55 min~, tenting it with
        @foil@:non-food once it is deep brown, until it sounds hollow underneath.
        """
    )
    .value

    return ScaledRecipe(
        asWritten: recipe,
        parser: parser,
        scale: scale
    )
}

@MainActor
private func previewBodyView(_ recipe: ScaledRecipe) -> RecipeBodyView {
    RecipeBodyView(
        presenter: RecipeFeaturePresenterStub(),
        recipe: recipe,
        metadata: RecipeDisplay.metadata(of: recipe.scaled.metadata),
        expandedSections: RecipeSection.openByDefault
    )
}

#Preview("Recipe body") {
    ScrollView {
        previewBodyView(previewRecipe())
            .sousPagePadding()
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    .sousPage()
}

#Preview("Recipe body, scaled") {
    ScrollView {
        previewBodyView(previewRecipe(scale: RecipeScale(target: .servings, value: 4.0)))
            .sousPagePadding()
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    .sousPage()
}

#Preview("Recipe body, side by side", traits: .fixedLayout(width: 1_210.0, height: 834.0)) {
    ScrollView {
        previewBodyView(previewRecipe())
            .sousPagePadding()
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    .environment(\.horizontalSizeClass, .regular)
    .sousPage()
}
