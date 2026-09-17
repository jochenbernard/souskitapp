import DesignSystem
import RecipeLibrary
import SousKit
import SwiftUI

/// A parsed recipe, top to bottom: the header, what it takes, and what to do.
struct RecipeBodyView: View {
    private let presenter: RecipeFeaturePresenterProtocol
    private let recipe: Recipe
    private let expandedSections: Set<RecipeSection>

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
        VStack(alignment: .leading, spacing: SousSpacing.xxLarge) {
            metadataView

            ingredientSection

            cookwareSection

            stepSection
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

    @ViewBuilder
    private var stepSection: some View {
        if !recipe.steps.isEmpty {
            section(.steps) {
                VStack(alignment: .leading, spacing: SousSpacing.xLarge) {
                    ForEach(StepNumbering.numberedGroups(of: recipe)) { numbered in
                        groupView(numbered)
                    }
                }
            }
        }
    }

    private func section(
        _ section: RecipeSection,
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        DisclosureGroup(
            section.label,
            isExpanded: isExpanded(section),
            content: content
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
            Text("Plus \(RecipeDisplay.joinedList(staples)) from the pantry.")
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

    private func groupView(_ numbered: NumberedGroup) -> some View {
        VStack(alignment: .leading, spacing: SousSpacing.small) {
            groupName(numbered.group)

            stepRows(numbered)
        }
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
    private func amountText(_ amount: Amount?) -> some View {
        if let amount {
            Text(verbatim: amount.text)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
    }

    private func stepView(_ step: Step, number: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: SousSpacing.medium) {
            stepNumber(number)

            stepProse(step)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, SousSpacing.large)
        .padding(.vertical, SousSpacing.medium)
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
