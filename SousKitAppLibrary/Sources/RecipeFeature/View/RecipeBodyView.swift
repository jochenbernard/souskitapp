import DesignSystem
import SousKit
import SwiftUI

/// A parsed recipe, top to bottom: the header, what it takes, and what to do.
struct RecipeBodyView: View {
    private let recipe: Recipe

    init(recipe: Recipe) {
        self.recipe = recipe
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SousSpacing.xxLarge) {
            headerSection

            ingredientSection

            cookwareSection

            stepSection
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: SousSpacing.medium) {
            title

            metadataRows
        }
    }

    @ViewBuilder
    private var ingredientSection: some View {
        if !recipe.ingredients.isEmpty {
            section("Ingredients") {
                VStack(alignment: .leading, spacing: SousSpacing.small) {
                    ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { _, ingredient in
                        ingredientRow(ingredient)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var cookwareSection: some View {
        let names = RecipeDisplay.cookwareNames(of: recipe)

        if !names.isEmpty {
            section("Cookware") {
                VStack(alignment: .leading, spacing: SousSpacing.small) {
                    ForEach(names, id: \.self) { name in
                        Text(verbatim: name)
                            .sousTextStyle(.body)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var stepSection: some View {
        if !recipe.steps.isEmpty {
            section("Steps") {
                VStack(alignment: .leading, spacing: SousSpacing.xLarge) {
                    ForEach(Array(recipe.groups.enumerated()), id: \.offset) { index, group in
                        groupView(group, firstNumber: RecipeDisplay.firstNumber(ofGroupAt: index, in: recipe))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var title: some View {
        if let name = recipe.metadata.title {
            Text(verbatim: name)
                .sousTextStyle(.title)
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
        }
    }

    private func section(
        _ label: LocalizedStringKey,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: SousSpacing.medium) {
            Text(label)
                .sousTextStyle(.eyebrow)
                .foregroundStyle(SousColor.textMuted)

            content()
        }
    }

    private func ingredientRow(_ ingredient: Ingredient) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: SousSpacing.small) {
            amountText(ingredient.amount)

            Text(verbatim: ingredient.name)
                .sousTextStyle(.body)
        }
    }

    private func groupView(_ group: StepGroup, firstNumber: Int) -> some View {
        VStack(alignment: .leading, spacing: SousSpacing.medium) {
            groupName(group)

            ForEach(Array(group.steps.enumerated()), id: \.offset) { index, step in
                stepView(step, number: firstNumber + index)
            }
        }
    }

    private func metadataRow(_ row: MetadataRow) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: SousSpacing.small) {
            metadataKey(row)

            Text(verbatim: row.value)
                .sousTextStyle(.data)
        }
    }

    @ViewBuilder
    private func amountText(_ amount: Amount?) -> some View {
        if let amount {
            Text(verbatim: amount.text)
                .sousTextStyle(.data)
                .foregroundStyle(SousColor.textMuted)
        }
    }

    @ViewBuilder
    private func groupName(_ group: StepGroup) -> some View {
        if let name = group.name {
            Text(verbatim: name)
                .sousTextStyle(.heading)
        }
    }

    private func stepView(_ step: Step, number: Int) -> some View {
        VStack(alignment: .leading, spacing: SousSpacing.xSmall) {
            Text(verbatim: String(number))
                .sousTextStyle(.eyebrow)
                .foregroundStyle(SousColor.textMuted)

            Text(verbatim: RecipeDisplay.prose(of: step))
                .sousTextStyle(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func metadataKey(_ row: MetadataRow) -> some View {
        if !row.key.isEmpty {
            Text(verbatim: row.key)
                .sousTextStyle(.data)
                .foregroundStyle(SousColor.textMuted)
        }
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
        RecipeBodyView(recipe: previewRecipe())
            .padding(SousSpacing.xLarge)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    .sousPage()
}
