import DesignSystem
import RecipeLibrary
import SousKit
import SwiftUI

/// A parsed recipe, top to bottom: the header, what it takes, and what to do.
struct RecipeBodyView: View {
    private let presenter: RecipeFeaturePresenterProtocol
    private let recipe: Recipe
    private let expandedSections: Set<RecipeSection>

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
            metadataRows

            ingredientSection

            cookwareSection

            stepSection
        }
    }

    @ViewBuilder
    private var metadataRows: some View {
        let rows = RecipeDisplay.metadataRows(of: recipe.metadata)

        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: SousSpacing.xSmall) {
                ForEach(rows) { row in
                    metadataRow(row)
                }
            }
            .font(.subheadline)
        }
    }

    @ViewBuilder
    private var ingredientSection: some View {
        let ingredients = recipe.ingredients

        if !ingredients.isEmpty {
            section(.ingredients) {
                VStack(alignment: .leading, spacing: SousSpacing.small) {
                    ForEach(ingredients.indices, id: \.self) { index in
                        ingredientRow(ingredients[index])
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var cookwareSection: some View {
        let names = RecipeDisplay.cookwareNames(of: recipe)

        if !names.isEmpty {
            section(.cookware) {
                VStack(alignment: .leading, spacing: SousSpacing.small) {
                    ForEach(names, id: \.self) { name in
                        Text(verbatim: name)
                    }
                }
                .font(.body)
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

    private func metadataRow(_ row: MetadataRow) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: SousSpacing.small) {
            metadataKey(row)

            Text(verbatim: row.value)
        }
    }

    private func section(
        _ section: RecipeSection,
        @ViewBuilder content: @escaping () -> some View
    ) -> some View {
        DisclosureGroup(section.label, isExpanded: isExpanded(section)) {
            // A disclosure group centers its content.
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func ingredientRow(_ ingredient: Ingredient) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: SousSpacing.small) {
            amountText(ingredient.amount)

            Text(verbatim: ingredient.name)
                .font(.body)
        }
    }

    private func groupView(_ numbered: NumberedGroup) -> some View {
        VStack(alignment: .leading, spacing: SousSpacing.medium) {
            groupName(numbered.group)

            ForEach(numbered.numberedSteps, id: \.number) { number, step in
                stepView(step, number: number)
            }
        }
    }

    @ViewBuilder
    private func metadataKey(_ row: MetadataRow) -> some View {
        if !row.key.isEmpty {
            Text(verbatim: row.key)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func amountText(_ amount: Amount?) -> some View {
        if let amount {
            Text(verbatim: amount.text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func groupName(_ group: StepGroup) -> some View {
        if let name = group.name {
            Text(verbatim: name)
                .font(.title3)
        }
    }

    private func stepView(_ step: Step, number: Int) -> some View {
        VStack(alignment: .leading, spacing: SousSpacing.xSmall) {
            Text(verbatim: String(number))
                .font(.caption2)
                .foregroundStyle(.secondary)

            stepProse(step)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
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
