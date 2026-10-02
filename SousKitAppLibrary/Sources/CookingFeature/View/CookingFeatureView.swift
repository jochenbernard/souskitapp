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

    // Where the timers stand between their stack and their list, which the blur behind them and the room the steps
    // keep clear of them follow.
    @State private var motion = RunningTimersMotion()
    @State private var topBarHeight = 0.0

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
        // A bar of the screen's own rather than the navigation bar, so the blur behind the open list covers it.
        .safeAreaBar(edge: .top) {
            topBar
                .onGeometryChange(for: CGFloat.self, of: \.size.height) { height in
                    topBarHeight = height
                }
        }
        .safeAreaInset(edge: .bottom) {
            stackRoom
        }
        .safeAreaInset(edge: .trailing) {
            sideTimers
        }
        .runningTimersBlur(motion: motion, isEnabled: isNarrow)
        .accessibilityHidden(isTimerListOpen)
        .sousPage()
        .overlay {
            foldingTimers
        }
        .animation(.runningTimers, value: viewModel.runningTimers)
        // Every start is felt, since a timer that joins the stack out of sight shows little of itself.
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.startedTimerCount)
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

    private var topBar: some View {
        CookingTopBar(
            presenter: presenter,
            title: viewModel.recipe.metadata.title ?? "",
            isConfirmingExit: viewModel.isConfirmingExit
        )
    }

    // The steps keep clear of the folded stack, which lies over them rather than among them.
    @ViewBuilder
    private var stackRoom: some View {
        if isNarrow {
            Color.clear
                .frame(height: motion.stackHeight)
        }
    }

    // A wide screen has room beside the steps, so the timers stay open there and cover none of them.
    @ViewBuilder
    private var sideTimers: some View {
        if !isNarrow, !viewModel.runningTimers.isEmpty {
            RunningTimersPanel(
                presenter: presenter,
                viewModel: viewModel,
                motion: motion,
                kind: .column,
                topInset: 0.0
            )
            .frame(width: sideTimersWidth)
            .padding(.bottom, SousSpacing.small)
            .padding(.trailing, SousSpacing.large)
            .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
    }

    // The stack and the list lie over the steps and the top bar alike, below the bar, so a tap anywhere beside the
    // open list closes it.
    @ViewBuilder
    private var foldingTimers: some View {
        if isNarrow {
            RunningTimersPanel(
                presenter: presenter,
                viewModel: viewModel,
                motion: motion,
                kind: .folding,
                topInset: topBarHeight
            )
        }
    }

    private var isNarrow: Bool {
        horizontalSizeClass != .regular
    }

    private var isTimerListOpen: Bool {
        isNarrow && viewModel.isTimerListOpen
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
    CookingFeatureView(
        presenter: CookingFeaturePresenterStub(),
        viewModel: CookingFeatureViewModel(recipe: previewRecipe())
    )
}

#Preview("Cooking, confirming the exit") {
    let viewModel = CookingFeatureViewModel(recipe: previewRecipe())
    viewModel.isConfirmingExit = true

    return CookingFeatureView(
        presenter: CookingFeaturePresenterStub(),
        viewModel: viewModel
    )
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

    return CookingFeatureView(
        presenter: CookingFeaturePresenterStub(),
        viewModel: viewModel
    )
}

#Preview("Cooking, with the timers open") {
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
        ),
        RunningTimer(
            id: UUID(),
            stepTimer: StepTimer(stepNumber: 1, text: "30 min", duration: .seconds(1_800)),
            endDate: date.addingTimeInterval(1_500),
            isRinging: false
        )
    ]
    viewModel.isTimerListOpen = true

    return CookingFeatureView(
        presenter: CookingFeaturePresenterStub(),
        viewModel: viewModel
    )
}

#Preview("Cooking, asking to allow timers") {
    let viewModel = CookingFeatureViewModel(recipe: previewRecipe())
    viewModel.isAskingToAllowTimers = true

    return CookingFeatureView(
        presenter: CookingFeaturePresenterStub(),
        viewModel: viewModel
    )
}
