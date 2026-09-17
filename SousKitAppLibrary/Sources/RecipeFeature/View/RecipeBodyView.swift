import DesignSystem
import RecipeLibrary
import SousKit
import SwiftUI

/// A parsed recipe: the header and what it takes, then what to do, side by side where the width allows.
struct RecipeBodyView: View {
    private let presenter: RecipeFeaturePresenterProtocol
    private let recipe: Recipe
    private let expandedSections: Set<RecipeSection>

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // The overview's width beside the steps, growing with Dynamic Type.
    @ScaledMetric(relativeTo: .body) private var overviewWidth = 360.0

    // A `.subheadline` number with room around it, growing with Dynamic Type.
    @ScaledMetric(relativeTo: .subheadline) private var stepNumberDiameter = 26.0

    init(
        presenter: RecipeFeaturePresenterProtocol,
        recipe: Recipe,
        expandedSections: Set<RecipeSection>
    ) {
        self.presenter = presenter
        self.recipe = recipe
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

    private var hasOverview: Bool {
        !RecipeDisplay.metadata(of: recipe.metadata).isEmpty || !recipe.ingredients.isEmpty || !recipe.cookware.isEmpty
    }

    // One layout either way, so a change of size class keeps the sections rather than rebuilding them.
    private var columns: AnyLayout {
        isSideBySide
            ? AnyLayout(HStackLayout(alignment: .top, spacing: SousSpacing.xxLarge))
            : AnyLayout(VStackLayout(alignment: .leading, spacing: SousSpacing.xxLarge))
    }

    @ViewBuilder
    private var overview: some View {
        if hasOverview {
            VStack(alignment: .leading, spacing: SousSpacing.xxLarge) {
                metadataView

                ingredientSection

                cookwareSection
            }
            .frame(maxWidth: isSideBySide ? overviewWidth : .infinity)
        }
    }

    @ViewBuilder
    private var stepSection: some View {
        if !recipe.steps.isEmpty {
            VStack(alignment: .leading, spacing: SousSpacing.xLarge) {
                ForEach(StepNumbering.numberedGroups(of: recipe)) { numbered in
                    groupView(numbered)
                }
            }
        }
    }

    @ViewBuilder
    private var metadataView: some View {
        let metadata = RecipeDisplay.metadata(of: recipe.metadata)

        if !metadata.isEmpty {
            RecipeMetadataView(metadata: metadata)
        }
    }

    @ViewBuilder
    private var ingredientSection: some View {
        let ingredientList = RecipeDisplay.ingredientList(of: recipe)

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
    private var cookwareSection: some View {
        let names = RecipeDisplay.cookwareNames(of: recipe)

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

    private func ingredientRows(_ ingredients: [Ingredient]) -> some View {
        VStack(spacing: 0.0) {
            ForEach(ingredients.indices, id: \.self) { index in
                rowDivider(isFirst: index == 0)

                ingredientRow(ingredients[index])
            }
        }
        .sousSurface(RoundedRectangle(cornerRadius: SousRadius.large))
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
        VStack(spacing: 0.0) {
            ForEach(numbered.numberedSteps, id: \.number) { number, step in
                rowDivider(isFirst: number == numbered.firstNumber)

                stepView(step, number: number)
            }
        }
        .sousSurface(RoundedRectangle(cornerRadius: SousRadius.large))
    }

    @ViewBuilder
    private func rowDivider(isFirst: Bool) -> some View {
        if !isFirst {
            Divider()
                .padding(.horizontal, SousSpacing.large)
        }
    }

    private func ingredientRow(_ ingredient: Ingredient) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: SousSpacing.medium) {
            Text(verbatim: ingredient.name)

            Spacer(minLength: 0.0)

            amountText(ingredient.amount)
        }
        .font(.body)
        .padding(.horizontal, SousSpacing.large)
        .padding(.vertical, SousSpacing.medium)
    }

    private func stepView(_ step: Step, number: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: SousSpacing.medium) {
            stepNumber(number)

            stepProse(step)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        // The number is the row's tallest line, so padding it evenly sets it as far from the top as from the side.
        .padding(SousSpacing.large)
    }

    @ViewBuilder
    private func amountText(_ amount: Amount?) -> some View {
        if let amount {
            Text(verbatim: amount.text)
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

private func previewRecipe() -> Recipe {
    SousParser().parseRecipe(
        """
        ---
        title: Crepes
        servings: 4
        yield: [12 crepes]
        prep-time: 10 min
        tags: [dessert, classic, french]
        ---

        Whisk @{200 g} flour@ into a batter with @{4} eggs@, @{500 ml} milk@, and
        @{1/2 tsp} salt@:staple in a #bowl#, then rest it ~1 h~.

        Wipe a #crepe pan# with @{10 g} butter@ over medium heat, ladle in a thin layer,
        and cook each crepe for ~1 min~ a side until lacy and gold.
        """
    )
    .value
}

#Preview("Recipe body") {
    ScrollView {
        RecipeBodyView(
            presenter: RecipeFeaturePresenterStub(),
            recipe: previewRecipe(),
            expandedSections: RecipeSection.openByDefault
        )
        .sousPagePadding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .sousPage()
}

#Preview("Recipe body, side by side", traits: .fixedLayout(width: 1_210.0, height: 834.0)) {
    ScrollView {
        RecipeBodyView(
            presenter: RecipeFeaturePresenterStub(),
            recipe: previewRecipe(),
            expandedSections: RecipeSection.openByDefault
        )
        .sousPagePadding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .environment(\.horizontalSizeClass, .regular)
    .sousPage()
}
