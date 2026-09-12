import DesignSystem
import Foundation
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
            headerSection

            ingredientSection

            cookwareSection

            stepSection
        }
        .animation(.spring(duration: 0.3, bounce: 0.0), value: expandedSections)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: SousSpacing.medium) {
            title

            metadataRows
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
                            .sousTextStyle(.body)
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
                        groupView(numbered.group, firstNumber: numbered.firstNumber)
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
        _ section: RecipeSection,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: SousSpacing.medium) {
            sectionHeading(section)

            if expandedSections.contains(section) {
                content()
            }
        }
    }

    private func sectionHeading(_ section: RecipeSection) -> some View {
        let isExpanded = expandedSections.contains(section)

        return Button(
            action: { presenter.didToggleSection(section) },
            label: { sectionHeadingLabel(section, isExpanded: isExpanded) }
        )
        .buttonStyle(.plain)
        .accessibilityValue(isExpanded ? Text("Expanded") : Text("Collapsed"))
    }

    private func sectionHeadingLabel(_ section: RecipeSection, isExpanded: Bool) -> some View {
        HStack(spacing: SousSpacing.small) {
            Text(section.label)
                .sousTextStyle(.eyebrow)
                .foregroundStyle(SousColor.textMuted)

            Spacer(minLength: 0.0)

            // Decorative: the button already reads as the section, expanded or collapsed.
            // Set in the label's own entry, so the chevron is drawn at the label's size.
            Image(systemName: "chevron.down")
                .sousFont(.eyebrow)
                .rotationEffect(.degrees(isExpanded ? 0.0 : -90.0))
                .foregroundStyle(SousColor.textMuted)
                .accessibilityHidden(true)
        }
        .contentShape(.rect)
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

            stepProse(step)
                .sousTextStyle(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// The step's prose, with what it reaches for underlined in the accent.
    private func stepProse(_ step: Step) -> Text {
        Text(StepProse.attributedProse(of: step, annotationColor: SousColor.accent))
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
        RecipeBodyView(
            presenter: RecipeFeaturePresenterStub(),
            recipe: previewRecipe(),
            expandedSections: RecipeSection.openByDefault
        )
        .padding(SousSpacing.xLarge)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .sousPage()
}
