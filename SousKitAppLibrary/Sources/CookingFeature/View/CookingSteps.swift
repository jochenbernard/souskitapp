import DesignSystem
import RecipeLibrary
import SousKit
import SwiftUI

/// A recipe's steps to cook from, numbered and grouped, each timer in them starting when tapped.
///
/// A view of its own, so the running timers changing leaves the steps as they are.
struct CookingSteps: View {
    private let presenter: CookingFeaturePresenterProtocol
    private let recipe: Recipe

    // A comfortable line length for the `.title3` steps, growing with Dynamic Type.
    @ScaledMetric(relativeTo: .title3) private var stepsWidth = 720.0

    // A `.body` number with room around it, growing with Dynamic Type.
    @ScaledMetric(relativeTo: .body) private var stepNumberDiameter = 32.0

    init(
        presenter: CookingFeaturePresenterProtocol,
        recipe: Recipe
    ) {
        self.presenter = presenter
        self.recipe = recipe
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SousSpacing.xxLarge) {
            ForEach(StepNumbering.numberedGroups(of: recipe)) { numbered in
                groupView(numbered)
            }
        }
        .frame(maxWidth: stepsWidth)
        .environment(\.openURL, OpenURLAction(handler: openTimer))
    }

    private func groupView(_ numbered: NumberedGroup) -> some View {
        VStack(alignment: .leading, spacing: SousSpacing.small) {
            groupName(numbered.group)

            stepRows(numbered)
        }
    }

    @ViewBuilder
    private func groupName(_ group: StepGroup) -> some View {
        if let name = group.name {
            Text(verbatim: name)
                .foregroundStyle(.secondary)
                .padding(.horizontal, SousSpacing.xLarge)
        }
    }

    private func stepRows(_ numbered: NumberedGroup) -> some View {
        SousRowGroup(dividerInset: SousSpacing.xLarge) {
            ForEach(numbered.numberedSteps, id: \.number) { number, step in
                stepView(step, number: number)
            }
        }
    }

    private func stepView(_ step: Step, number: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: SousSpacing.large) {
            stepNumber(number)

            stepProse(step, number: number)
                .font(.title3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        // The number is the row's tallest line, so padding it evenly sets it as far from the top as from the side.
        .padding(SousSpacing.xLarge)
    }

    private func stepNumber(_ number: Int) -> some View {
        Text(verbatim: String(number))
            .monospacedDigit()
            .frame(width: stepNumberDiameter, height: stepNumberDiameter)
            .background(.tertiaryFill, in: Circle())
    }

    private func stepProse(_ step: Step, number: Int) -> Text {
        Text(
            StepProse.attributedProse(
                of: step,
                annotationColor: .accent,
                timerLink: { StepTimer($0, stepNumber: number)?.link }
            )
        )
    }

    private func openTimer(_ link: URL) -> OpenURLAction.Result {
        guard let timer = StepTimer(link: link) else {
            return .systemAction
        }

        Task {
            await presenter.didTapTimer(timer)
        }
        return .handled
    }
}

#Preview("Cooking steps") {
    ScrollView {
        CookingSteps(
            presenter: CookingFeaturePresenterStub(),
            recipe: SousParser().parseRecipe(
                """
                Rub @{125 g} butter@ into @{250 g} flour@ and rest the dough in the fridge for ~30 min~.

                Fry @{200 g} lardons@ in a #frying pan# for ~5-6 min~ until the fat runs.
                """
            )
            .value
        )
        .sousPagePadding()
    }
    .sousPage()
}
