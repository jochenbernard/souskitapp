import DesignSystem
import SousKit
import SwiftUI

struct CookingFeatureView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.openURL) private var openURL

    private let presenter: CookingFeaturePresenterProtocol
    private let viewModel: CookingFeatureViewModel

    // Room for a `.title2` countdown beside its label, growing with Dynamic Type.
    @ScaledMetric(relativeTo: .title2) private var sideTimersWidth = 340.0

    // Where the timers stand between their stack and their list, which the blur behind them and the room the steps
    // keep clear of them follow.
    @State private var motion = RunningTimersMotion()
    @State private var topBarHeight = 0.0
    @State private var areStepsScrolled = false

    init(
        presenter: CookingFeaturePresenterProtocol,
        viewModel: CookingFeatureViewModel
    ) {
        self.presenter = presenter
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            CookingSteps(presenter: presenter, viewModel: viewModel)
                .sousPagePadding()
                .frame(maxWidth: .infinity)
        }
        .onScrollGeometryChange(for: Bool.self, of: isScrolled) { _, isScrolled in
            areStepsScrolled = isScrolled
        }
        // The bar's background is drawn here instead, for the timers scrolling beside the steps too.
        .scrollEdgeEffectHidden(!isNarrow, for: .top)
        .safeAreaInset(edge: .bottom) {
            stackRoom
        }
        .safeAreaInset(edge: .trailing) {
            sideTimers
        }
        // A bar of the screen's own rather than the navigation bar, so the blur behind the open list covers it.
        .safeAreaBar(edge: .top) {
            topBar
                .onGeometryChange(for: CGFloat.self, of: \.size.height) { height in
                    topBarHeight = height
                }
                .background {
                    topBarBackground
                }
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
        // VoiceOver stays on a full screen cover under a sheet this low, unless the cover is hidden from it.
        .accessibilityHidden(viewModel.isAddingTimer)
        .sheet(isPresented: isAddingTimer) {
            newTimerSheet
        }
        .task {
            await presenter.viewDidAppear()
        }
        .onDisappear(perform: presenter.viewDidDisappear)
    }

    // The steps keep clear of the folded stack, which lies over them rather than among them.
    @ViewBuilder
    private var stackRoom: some View {
        if isNarrow {
            Color.clear
                .frame(height: motion.stackHeight)
        }
    }

    // A wide screen has room beside the steps, so the timers stay open there, scrolling on under the bar.
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

    private var topBar: some View {
        CookingTopBar(
            presenter: presenter,
            title: viewModel.title,
            isConfirmingExit: viewModel.isConfirmingExit
        )
    }

    @ViewBuilder
    private var topBarBackground: some View {
        if !isNarrow {
            CookingTopBarBackground(motion: motion, areStepsScrolled: areStepsScrolled)
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

    private func isScrolled(_ geometry: ScrollGeometry) -> Bool {
        geometry.contentOffset.y + geometry.contentInsets.top > 0.0
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

    private var newTimerSheet: some View {
        NewTimerSheet(presenter: presenter, entry: viewModel.newTimer)
    }

    private var isAddingTimer: Binding<Bool> {
        Binding(
            get: { viewModel.isAddingTimer },
            set: { presenter.didChangeIsAddingTimer($0) }
        )
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
        viewModel: CookingFeatureViewModel(
            recipe: previewRecipe(),
            title: "Quiche Lorraine"
        )
    )
}

#Preview("Cooking, confirming the exit") {
    let viewModel = CookingFeatureViewModel(
        recipe: previewRecipe(),
        title: "Quiche Lorraine"
    )
    viewModel.isConfirmingExit = true

    return CookingFeatureView(
        presenter: CookingFeaturePresenterStub(),
        viewModel: viewModel
    )
}

#Preview("Cooking, with timers running") {
    CookingFeatureView(
        presenter: CookingFeaturePresenterStub(),
        viewModel: RunningTimersPreview.viewModel(
            isTimerListOpen: false,
            recipe: previewRecipe(),
            title: "Quiche Lorraine"
        )
    )
}

#Preview("Cooking, with the timers open") {
    CookingFeatureView(
        presenter: CookingFeaturePresenterStub(),
        viewModel: RunningTimersPreview.viewModel(
            isTimerListOpen: true,
            recipe: previewRecipe(),
            title: "Quiche Lorraine"
        )
    )
}

#Preview("Cooking, asking to allow timers") {
    let viewModel = CookingFeatureViewModel(
        recipe: previewRecipe(),
        title: "Quiche Lorraine"
    )
    viewModel.isAskingToAllowTimers = true

    return CookingFeatureView(
        presenter: CookingFeaturePresenterStub(),
        viewModel: viewModel
    )
}
