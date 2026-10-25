import DesignSystem
import RecipeLibrary
import RecipeScaling
import SousKit
import SwiftUI

/// A parsed recipe: the header and what it takes, then what to do, side by side where the width allows.
///
/// Side by side, each column scrolls on its own; one above the other, the body goes in the screen's scroll view.
struct RecipeBodyView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.isSousLoading) private var isLoading

    private let presenter: RecipeFeaturePresenterProtocol
    private let recipe: ScaledRecipe
    private let metadata: MetadataDisplay
    private let expandedSections: Set<RecipeSection>
    private let overviewWidth: Double
    private let header: RecipeHeaderView?

    @State private var isOverviewScrolled = false
    @State private var areStepsScrolled = false

    // A `.subheadline` number with room around it, growing with Dynamic Type.
    @ScaledMetric(relativeTo: .subheadline) private var stepNumberDiameter = 26.0

    /// - Parameters:
    ///   - overviewWidth: The overview's width beside the steps.
    ///   - header: What the header card opens with, or `nil` for the card alone.
    init(
        presenter: RecipeFeaturePresenterProtocol,
        recipe: ScaledRecipe,
        metadata: MetadataDisplay,
        expandedSections: Set<RecipeSection>,
        overviewWidth: Double,
        header: RecipeHeaderView?
    ) {
        self.presenter = presenter
        self.recipe = recipe
        self.metadata = metadata
        self.expandedSections = expandedSections
        self.overviewWidth = overviewWidth
        self.header = header
    }

    var body: some View {
        if isSideBySide {
            HStack(alignment: .top, spacing: 0.0) {
                ScrollView {
                    overview
                        .sousPagePadding()
                }
                // At most its width, so the steps keep room at the largest text sizes.
                .frame(maxWidth: overviewWidth + SousSpacing.large * 2.0)
                .onScrollGeometryChange(for: Bool.self, of: isScrolled) { _, isScrolled in
                    isOverviewScrolled = isScrolled
                }

                ScrollView {
                    stepSection
                        .sousPagePadding()
                        .padding(.leading, SousSpacing.large)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .onScrollGeometryChange(for: Bool.self, of: isScrolled) { _, isScrolled in
                    areStepsScrolled = isScrolled
                }
            }
            // Both columns sit under one bar, so either one scrolled under it shows the bar across both.
            .scrollEdgeEffectHidden(true, for: .top)
            // Drawn here, since a background set on the navigation bar collapses the kitchen's large title on a pop.
            .overlay(alignment: .top) {
                barBackground
            }
        } else {
            VStack(alignment: .leading, spacing: SousSpacing.xxLarge) {
                overview

                stepSection
            }
        }
    }

    private var isSideBySide: Bool {
        horizontalSizeClass == .regular
    }

    private func isScrolled(_ geometry: ScrollGeometry) -> Bool {
        geometry.contentOffset.y + geometry.contentInsets.top > 0.0
    }

    private var isBarBackgroundShown: Bool {
        isOverviewScrolled || areStepsScrolled
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
        // At the top: it is measured a fraction narrower than it is laid out, where a line can wrap once more.
        .frame(maxWidth: isSideBySide ? overviewWidth : .infinity, alignment: .top)
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

    // No taller than the columns' top edge, so ignoring the safe area stretches it over the bar alone.
    private var barBackground: some View {
        Color.clear
            .frame(height: 0.0)
            .background(alignment: .bottom) {
                Rectangle()
                    .fill(.bar)
                    .overlay(alignment: .bottom) {
                        Divider()
                    }
                    .ignoresSafeArea(edges: .top)
            }
            .opacity(isBarBackgroundShown ? 1.0 : 0.0)
            .animation(.spring(duration: 0.2, bounce: 0.0), value: isBarBackgroundShown)
    }

    private var metadataView: some View {
        RecipeMetadataView(
            presenter: presenter,
            metadata: metadata,
            scale: recipe.scale,
            header: header,
            tagRowCount: nil
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
                    .sousLoadingPlaceholder()
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
        // A heading over placeholders leads nowhere yet, so only the screen's note on the wait is read.
        .accessibilityHidden(isLoading)
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
                .sousLoadingPlaceholder()
                .padding(.horizontal, SousSpacing.large)
        }
    }

    private func surface(@ViewBuilder content: () -> some View) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(SousSpacing.large)
            .sousRowSurface()
    }

    @ViewBuilder
    private func groupName(_ group: StepGroup) -> some View {
        if let name = group.name {
            Text(verbatim: name)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .sousLoadingPlaceholder()
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
        .sousLoadingPlaceholder()
        .sousRowPadding()
    }

    private func stepView(_ step: Step, number: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: SousSpacing.medium) {
            stepNumber(number)

            stepProse(step)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .sousLoadingPlaceholder()
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
        // A placeholder's bars carry no accent, which means live.
        Text(StepProse.attributedProse(of: step, annotationColor: isLoading ? .clear : .accent))
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
        expandedSections: RecipeSection.openByDefault,
        overviewWidth: 360.0,
        header: nil
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
    previewBodyView(previewRecipe())
        .environment(\.horizontalSizeClass, .regular)
        .sousPage()
}
