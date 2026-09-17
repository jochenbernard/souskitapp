import DesignSystem
import RecipeLibrary
import SousKit
import SwiftUI

struct CookingFeatureView: View {
    private let presenter: CookingFeaturePresenterProtocol
    private let viewModel: CookingFeatureViewModel

    // A comfortable line length for the `.title3` steps, growing with Dynamic Type.
    @ScaledMetric(relativeTo: .title3) private var stepsWidth = 720.0

    // A `.body` number with room around it, growing with Dynamic Type.
    @ScaledMetric(relativeTo: .body) private var stepNumberDiameter = 32.0

    init(
        presenter: CookingFeaturePresenterProtocol,
        viewModel: CookingFeatureViewModel
    ) {
        self.presenter = presenter
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            steps
                .frame(maxWidth: stepsWidth)
                .sousPagePadding()
                .frame(maxWidth: .infinity)
        }
        .sousPage()
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        // Hiding it also turns off the swipe back, which leaves the confirmation as the only way out.
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                exitButton
            }
        }
        .onAppear(perform: presenter.viewDidAppear)
        .onDisappear(perform: presenter.viewDidDisappear)
    }

    private var navigationTitle: String {
        viewModel.recipe.metadata.title ?? ""
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: SousSpacing.xxLarge) {
            ForEach(StepNumbering.numberedGroups(of: viewModel.recipe)) { numbered in
                groupView(numbered)
            }
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
        HStack(alignment: .firstTextBaseline, spacing: SousSpacing.large) {
            stepNumber(number)

            stepProse(step)
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

    private func stepProse(_ step: Step) -> Text {
        Text(StepProse.attributedProse(of: step, annotationColor: .accent))
    }

    private var exitButton: some View {
        Button(role: .close, action: presenter.didTapExit)
            .confirmationDialog(
                Text("Are you sure you want to stop cooking?", bundle: .module),
                isPresented: isConfirmingExit,
                titleVisibility: .visible,
                actions: { confirmExitButton }
            )
    }

    private var confirmExitButton: some View {
        Button(role: .destructive, action: presenter.didConfirmExit) {
            Text("Stop cooking", bundle: .module)
        }
    }

    private var isConfirmingExit: Binding<Bool> {
        Binding(
            get: { viewModel.isConfirmingExit },
            set: { presenter.didChangeIsConfirmingExit($0) }
        )
    }
}

private func previewRecipe() -> Recipe {
    SousParser().parseRecipe(
        """
        ---
        title: Crepes
        servings: 4
        ---

        ## Batter

        Whisk @{200 g} flour@ into a batter with @{4} eggs@, @{500 ml} milk@, and
        @{1/2 tsp} salt@:staple in a #bowl#, then rest it ~1 h~.

        ## Crepes

        Wipe a #crepe pan# with @{10 g} butter@ over medium heat, ladle in a thin layer,
        and cook each crepe for ~1 min~ a side until lacy and gold.

        Stack them under a cloth and serve with sugar and lemon.
        """
    )
    .value
}

#Preview("Cooking") {
    NavigationStack {
        CookingFeatureView(
            presenter: CookingFeaturePresenterStub(),
            viewModel: CookingFeatureViewModel(recipe: previewRecipe())
        )
    }
}

#Preview("Cooking, confirming the exit") {
    let viewModel = CookingFeatureViewModel(recipe: previewRecipe())
    viewModel.isConfirmingExit = true

    return NavigationStack {
        CookingFeatureView(
            presenter: CookingFeaturePresenterStub(),
            viewModel: viewModel
        )
    }
}
