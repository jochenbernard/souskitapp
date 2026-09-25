import DesignSystem
import RecipeLibrary
import SousKit
import SwiftUI

struct CookingFeatureView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.openURL) private var openURL

    private let presenter: CookingFeaturePresenterProtocol
    private let viewModel: CookingFeatureViewModel

    // A comfortable line length for the `.title3` steps, growing with Dynamic Type.
    @ScaledMetric(relativeTo: .title3) private var stepsWidth = 720.0

    // A `.body` number with room around it, growing with Dynamic Type.
    @ScaledMetric(relativeTo: .body) private var stepNumberDiameter = 32.0

    // Room for a `.title2` countdown beside its step, growing with Dynamic Type.
    @ScaledMetric(relativeTo: .title2) private var sideTimersWidth = 340.0

    // Two and a half `.title2` rows: the half row shows there are more to scroll to.
    @ScaledMetric(relativeTo: .title2) private var bottomTimersMaxHeight = 160.0

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
        .environment(\.openURL, OpenURLAction(handler: openTimer))
        .safeAreaInset(edge: .bottom) {
            bottomTimers
        }
        .safeAreaInset(edge: .trailing) {
            sideTimers
        }
        .animation(RunningTimersTray.animation, value: viewModel.runningTimers)
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
        .alert(
            Text("Allow timers", bundle: .module),
            isPresented: isAskingToAllowTimers,
            actions: { allowTimersButtons },
            message: { allowTimersMessage }
        )
        .task {
            await presenter.viewDidAppear()
        }
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

    @ViewBuilder
    private var bottomTimers: some View {
        if horizontalSizeClass != .regular, !viewModel.runningTimers.isEmpty {
            timersTray(maxHeight: bottomTimersMaxHeight)
                .padding(.horizontal, SousSpacing.large)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    // A wide screen has room beside the steps, so the timers cover none of them there.
    @ViewBuilder
    private var sideTimers: some View {
        if horizontalSizeClass == .regular, !viewModel.runningTimers.isEmpty {
            timersTray(maxHeight: .infinity)
                .frame(width: sideTimersWidth)
                .padding(.vertical, SousSpacing.small)
                .padding(.trailing, SousSpacing.large)
                .frame(maxHeight: .infinity, alignment: .top)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
    }

    private func timersTray(maxHeight: CGFloat) -> some View {
        RunningTimersTray(
            presenter: presenter,
            timers: viewModel.runningTimers,
            timerConfirmingCancel: viewModel.timerConfirmingCancel,
            maxHeight: maxHeight
        )
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

    @ViewBuilder
    private var allowTimersButtons: some View {
        Button(action: openSettings) {
            Text("Open Settings", bundle: .module)
        }

        Button(role: .cancel, action: {})
    }

    private var allowTimersMessage: Text {
        Text(
            "Allow timers in Settings, so a timer keeps running and goes off, even with the app closed.",
            bundle: .module
        )
    }

    private var isAskingToAllowTimers: Binding<Bool> {
        Binding(
            get: { viewModel.isAskingToAllowTimers },
            set: { presenter.didChangeIsAskingToAllowTimers($0) }
        )
    }

    private var isConfirmingExit: Binding<Bool> {
        Binding(
            get: { viewModel.isConfirmingExit },
            set: { presenter.didChangeIsConfirmingExit($0) }
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

    private func openSettings() {
        guard let settings = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        openURL(settings)
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

#Preview("Cooking, with timers running") {
    let date = Date.now
    let viewModel = CookingFeatureViewModel(recipe: previewRecipe())
    viewModel.runningTimers = [
        RunningTimer(
            id: UUID(),
            stepTimer: StepTimer(stepNumber: 2, text: "5-6 min", duration: .seconds(300)),
            endDate: date,
            isRinging: true
        ),
        RunningTimer(
            id: UUID(),
            stepTimer: StepTimer(stepNumber: 3, text: "15 min", duration: .seconds(900)),
            endDate: date.addingTimeInterval(260),
            isRinging: false
        )
    ]

    return NavigationStack {
        CookingFeatureView(
            presenter: CookingFeaturePresenterStub(),
            viewModel: viewModel
        )
    }
}

#Preview("Cooking, asking to allow timers") {
    let viewModel = CookingFeatureViewModel(recipe: previewRecipe())
    viewModel.isAskingToAllowTimers = true

    return NavigationStack {
        CookingFeatureView(
            presenter: CookingFeaturePresenterStub(),
            viewModel: viewModel
        )
    }
}
