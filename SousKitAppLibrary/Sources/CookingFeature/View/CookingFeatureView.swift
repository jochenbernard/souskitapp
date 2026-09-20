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
        title: Quiche Lorraine
        language: en
        version: 1.0
        servings: 6
        prep-time: 30 min
        cook-time: 50 min
        tags: [lunch, classic, french]
        allergens: [gluten, dairy, eggs]
        ---

        ## Pastry
        Rub @{125 g} butter@ into @{250 g} flour@ with @{1/2 tsp} salt@:staple in a
        #mixing bowl# until it looks like breadcrumbs, bind it with @{3 tbsp} water@, and
        rest the dough in the fridge for ~30 min~.

        ## Filling
        Fry @{200 g} lardons@ in a #frying pan# over medium heat for ~5-6 min~ until the
        fat runs, drain them, and stir them through @{4} eggs@ beaten with
        @{300 ml} cream@, @{1/4 tsp} nutmeg@, and @black pepper@:staple.

        ## Assemble
        Roll the >pastry> out and line a 24 cm #tart tin#. Cover it with @parchment@:non-food,
        fill it with @{500 g} baking beans@:non-food, and bake it blind at 190C for ~15 min~.
        Lift them out, pour in the >filling>, scatter over @{50 g} gruyere@?, and bake at
        180C for ~35 min~ until just set.
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
