import DesignSystem
import RecipeLibrary
import SousKit
import SwiftUI

struct CookingFeatureView: View {
    private let presenter: CookingFeaturePresenterProtocol
    private let viewModel: CookingFeatureViewModel

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
                .padding(.horizontal, SousSpacing.large)
                .padding(.vertical, SousSpacing.small)
                .frame(maxWidth: .infinity, alignment: .leading)
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

    /// The recipe's own title, or nothing where the recipe carries none.
    private var navigationTitle: String {
        viewModel.recipe.metadata.title ?? ""
    }

    /// The recipe's groups in order, with the steps numbered on across them.
    private var steps: some View {
        VStack(alignment: .leading, spacing: SousSpacing.section) {
            ForEach(StepNumbering.numberedGroups(of: viewModel.recipe)) { numbered in
                groupView(numbered.group, firstNumber: numbered.firstNumber)
            }
        }
    }

    private func groupView(_ group: StepGroup, firstNumber: Int) -> some View {
        VStack(alignment: .leading, spacing: SousSpacing.xxLarge) {
            groupName(group)

            ForEach(Array(group.steps.enumerated()), id: \.offset) { index, step in
                stepView(step, number: firstNumber + index)
            }
        }
    }

    @ViewBuilder
    private func groupName(_ group: StepGroup) -> some View {
        if let name = group.name {
            Text(verbatim: name)
                .font(.title)
        }
    }

    private func stepView(_ step: Step, number: Int) -> some View {
        VStack(alignment: .leading, spacing: SousSpacing.small) {
            Text(verbatim: String(number))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            stepProse(step)
                .font(.title3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// The step's prose, with what it reaches for underlined in the accent.
    private func stepProse(_ step: Step) -> Text {
        Text(StepProse.attributedProse(of: step, annotationColor: .accent))
    }

    private var exitButton: some View {
        Button(role: .close, action: presenter.didTapExit)
            .confirmationDialog(
                "Stop cooking?",
                isPresented: isConfirmingExit,
                titleVisibility: .visible
            ) {
                Button(
                    "Stop cooking",
                    role: .destructive,
                    action: presenter.didConfirmExit
                )
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
