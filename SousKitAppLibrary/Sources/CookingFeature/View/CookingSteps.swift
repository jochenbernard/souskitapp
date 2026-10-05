import DesignSystem
import RecipeLibrary
import SousKit
import SwiftUI

/// A recipe's steps to cook from, numbered and grouped, each ticked off through its number and each timer in them
/// starting when tapped.
///
/// A view of its own, so the running timers changing leaves the steps as they are.
struct CookingSteps: View {
    private let presenter: CookingFeaturePresenterProtocol
    private let viewModel: CookingFeatureViewModel

    // Steps done before the steps appear, such as restored ones, show their check without drawing it on.
    @State private var hasAppeared = false

    // A comfortable line length for the `.title3` steps, growing with Dynamic Type.
    @ScaledMetric(relativeTo: .title3) private var stepsWidth = 720.0

    // A `.body` number with room around it, growing with Dynamic Type.
    @ScaledMetric(relativeTo: .body) private var stepNumberDiameter = 32.0

    // A check that marks a done step on the number's corner, growing with it.
    @ScaledMetric(relativeTo: .body) private var doneBadgeDiameter = 20.0
    // Far enough out to clear a two-digit number.
    @ScaledMetric(relativeTo: .body) private var doneBadgeOffset = 9.0

    init(
        presenter: CookingFeaturePresenterProtocol,
        viewModel: CookingFeatureViewModel
    ) {
        self.presenter = presenter
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SousSpacing.xxLarge) {
            ForEach(StepNumbering.numberedGroups(of: viewModel.recipe)) { numbered in
                groupView(numbered)
            }
        }
        .frame(maxWidth: stepsWidth)
        .environment(\.openURL, OpenURLAction(handler: openTimer))
        .animation(.spring(duration: 0.3, bounce: 0.0), value: viewModel.completedStepNumbers)
        .onAppear {
            hasAppeared = true
        }
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
        let progress = viewModel.progress(ofStep: number)

        return HStack(alignment: .firstTextBaseline, spacing: SousSpacing.large) {
            stepToggle(number, progress: progress)

            stepProse(
                step,
                number: number,
                progress: progress
            )
            .font(.title3)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        // The number is the row's tallest line, so padding it evenly sets it as far from the top as from the side.
        .padding(SousSpacing.xLarge)
    }

    private func stepToggle(_ number: Int, progress: StepProgress) -> some View {
        Button(
            action: { presenter.didToggleStep(number) },
            label: {
                stepMark(number, progress: progress)
                    .frame(width: stepNumberDiameter, height: stepNumberDiameter)
                    .background(markFill(progress), in: Circle())
                    .overlay(alignment: .bottomTrailing) {
                        doneBadge(isDone: progress == .done)
                    }
                    // A target a finger finds without aiming, inside the room the row's padding leaves.
                    .padding(SousSpacing.small)
                    .contentShape(.rect)
            }
        )
        .buttonStyle(.sousBare)
        .padding(-SousSpacing.small)
        .accessibilityLabel(Text("Step \(number)", bundle: .module))
        .accessibilityValue(progressDescription(progress))
        .accessibilityHint(toggleHint(progress))
        .accessibilityAddTraits(.isToggle)
    }

    // A done step keeps its number, since a timer names the step it belongs to by number.
    private func stepMark(_ number: Int, progress: StepProgress) -> some View {
        Text(verbatim: String(number))
            .monospacedDigit()
            .foregroundStyle(numberStyle(progress))
    }

    private func numberStyle(_ progress: StepProgress) -> Color {
        switch progress {
        case .done:
            .secondary

        case .current:
            .white

        case .upcoming:
            .primary
        }
    }

    private func markFill(_ progress: StepProgress) -> Color {
        switch progress {
        case .done, .upcoming:
            .tertiaryFill

        case .current:
            .accent
        }
    }

    // The badge comes and goes inside a frame that stays where it sits, so it grows in from its own centre.
    private func doneBadge(isDone: Bool) -> some View {
        ZStack {
            if isDone {
                StepDoneBadge(drawsOn: hasAppeared)
                    .transition(
                        .asymmetric(
                            insertion: .scale.combined(with: .opacity).animation(.spring(duration: 0.35, bounce: 0.3)),
                            removal: .opacity
                        )
                    )
            }
        }
        .frame(width: doneBadgeDiameter, height: doneBadgeDiameter)
        .offset(x: doneBadgeOffset, y: doneBadgeOffset)
    }

    private func progressDescription(_ progress: StepProgress) -> Text {
        switch progress {
        case .done:
            Text("Done", bundle: .module)

        case .current:
            Text("In progress", bundle: .module)

        case .upcoming:
            Text(verbatim: "")
        }
    }

    private func toggleHint(_ progress: StepProgress) -> Text {
        switch progress {
        case .done:
            Text("Marks the step as not done", bundle: .module)

        case .current, .upcoming:
            Text("Marks the step as done", bundle: .module)
        }
    }

    @ViewBuilder
    private func stepProse(
        _ step: Step,
        number: Int,
        progress: StepProgress
    ) -> some View {
        switch progress {
        case .done:
            // A done step recedes, its timers included, so the steps ahead stand out.
            stepText(
                step,
                number: number,
                annotationColor: .secondary
            )
            .foregroundStyle(.secondary)
            .tint(.secondary)

        case .current, .upcoming:
            stepText(
                step,
                number: number,
                annotationColor: .accent
            )
        }
    }

    private func stepText(
        _ step: Step,
        number: Int,
        annotationColor: Color
    ) -> Text {
        Text(
            StepProse.attributedProse(
                of: step,
                annotationColor: annotationColor,
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

private func previewViewModel() -> CookingFeatureViewModel {
    CookingFeatureViewModel(
        recipe: SousParser().parseRecipe(
            """
            Rub @{125 g} butter@ into @{250 g} flour@ and rest the dough in the fridge for ~30 min~.

            Fry @{200 g} lardons@ in a #frying pan# for ~5-6 min~ until the fat runs.

            Pour in the >filling> and bake at 180C for ~35 min~ until just set.
            """
        )
        .value,
        title: "Quiche Lorraine"
    )
}

#Preview("Cooking steps") {
    ScrollView {
        CookingSteps(
            presenter: CookingFeaturePresenterStub(),
            viewModel: previewViewModel()
        )
        .sousPagePadding()
    }
    .sousPage()
}

#Preview("Cooking steps, the first one done") {
    let viewModel = previewViewModel()
    viewModel.completedStepNumbers = [1]

    return ScrollView {
        CookingSteps(
            presenter: CookingFeaturePresenterStub(),
            viewModel: viewModel
        )
        .sousPagePadding()
    }
    .sousPage()
}
