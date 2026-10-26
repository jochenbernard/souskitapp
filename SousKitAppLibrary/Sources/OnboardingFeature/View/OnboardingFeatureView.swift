import DesignSystem
import SwiftUI
import UniformTypeIdentifiers

struct OnboardingFeatureView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // The cards' widths on a phone, and where the page is wide.
    private static let compactCardWidths = 120.0...160.0
    private static let regularCardWidths = 200.0...250.0

    // The cards fan out once, then the copy rises in under them. Without motion, both fade in where they rest.
    private static let fanEntrance = Animation.spring(duration: 0.7, bounce: 0.3).delay(0.35)
    private static let stillFanEntrance = Animation.spring(duration: 0.5, bounce: 0.0).delay(0.2)
    private static let copyEntrance = Animation.spring(duration: 0.6, bounce: 0.0).delay(0.6)

    // How much smaller the fan starts, and how far below its place the copy starts.
    private static let stackedFanScale = 0.92
    private static let copyRise = 24.0

    private let presenter: OnboardingFeaturePresenterProtocol
    private let viewModel: OnboardingFeatureViewModel

    // A comfortable line length for the copy where the page is wide, growing with Dynamic Type.
    @ScaledMetric(relativeTo: .body) private var columnWidth = 440.0

    @State private var visibleHeight = 0.0
    @State private var isFanned = false
    @State private var showsCopy = false

    init(
        presenter: OnboardingFeaturePresenterProtocol,
        viewModel: OnboardingFeatureViewModel
    ) {
        self.presenter = presenter
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            content
                .frame(maxWidth: .infinity, minHeight: visibleHeight)
        }
        .scrollBounceBehavior(.basedOnSize)
        // The scroll view's own size is the screen between its bars.
        .onScrollGeometryChange(
            for: Double.self,
            of: { $0.containerSize.height },
            action: { _, newHeight in visibleHeight = newHeight }
        )
        .scrollEdgeEffectStyle(.soft, for: .bottom)
        .safeAreaBar(edge: .bottom) {
            bottomBar
        }
        .sousPage()
        .fileImporter(
            isPresented: isChoosingDirectory,
            allowedContentTypes: [.folder],
            onCompletion: presenter.didChooseDirectory
        )
        .onAppear(perform: enter)
    }

    private var isCompact: Bool {
        horizontalSizeClass != .regular
    }

    @ViewBuilder
    private var content: some View {
        if isCompact {
            phoneContent
        } else {
            // The fan beside the copy where both fit at their size, above it where they do not.
            ViewThatFits(in: .horizontal) {
                sideBySideContent

                stackedContent
            }
        }
    }

    // The fan in the room the copy leaves, and the actions in reach in the bar.
    private var phoneContent: some View {
        VStack(alignment: .leading, spacing: SousSpacing.xxLarge) {
            fan(cardWidths: Self.compactCardWidths)
                .frame(maxHeight: .infinity)

            copy
        }
        .sousPagePadding()
    }

    private var sideBySideContent: some View {
        HStack(spacing: SousSpacing.section) {
            fan(cardWidths: Self.regularCardWidths)

            VStack(alignment: .leading, spacing: SousSpacing.xxLarge) {
                copy

                actions
            }
            .frame(width: columnWidth)
        }
        .padding(.horizontal, SousSpacing.page)
        .padding(.vertical, SousSpacing.xxLarge)
    }

    private var stackedContent: some View {
        VStack(alignment: .leading, spacing: SousSpacing.xxLarge) {
            fan(cardWidths: Self.regularCardWidths)

            copy

            actions
        }
        .frame(maxWidth: columnWidth)
        .sousPagePadding()
        .padding(.vertical, SousSpacing.xxLarge)
    }

    @ViewBuilder
    private var bottomBar: some View {
        if isCompact {
            actions
                .sousPagePadding()
        }
    }

    private func fan(cardWidths: ClosedRange<Double>) -> some View {
        let isLaidOut = isFanned || reduceMotion

        return OnboardingShowcaseFan(cardWidths: cardWidths, isFanned: isLaidOut)
            .scaleEffect(isLaidOut ? 1.0 : Self.stackedFanScale)
            // Fading as one picture, so the cards under the top one stay hidden while it fades in.
            .compositingGroup()
            .opacity(isFanned ? 1.0 : 0.0)
    }

    private var copy: some View {
        VStack(alignment: .leading, spacing: SousSpacing.xLarge) {
            introduction
                .offset(y: showsCopy || reduceMotion ? 0.0 : Self.copyRise)
                .opacity(showsCopy ? 1.0 : 0.0)

            failureNote
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // Whole, however little room the fan leaves.
        .fixedSize(horizontal: false, vertical: true)
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: SousSpacing.medium) {
            SousLockup(markSize: 32.0, wordmarkSize: 24.0)

            Text("Your recipes, ready to cook", bundle: .module)
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)

            Text(
                """
                Sous reads your recipes from a folder of .sous files. Choose that folder to start; you can \
                change it later in Settings.
                """,
                bundle: .module
            )
            .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var failureNote: some View {
        if let failureMessage = viewModel.failureMessage {
            Text(failureMessage)
                .sousCallout()
        }
    }

    private var actions: some View {
        VStack(spacing: SousSpacing.medium) {
            mockRecipesButton

            chooseButton
        }
    }

    @ViewBuilder
    private var mockRecipesButton: some View {
        #if DEBUG
        Button(action: presenter.didTapUseMockRecipes) {
            Text("Use mock recipes", bundle: .module)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.sousQuiet)
        #endif
    }

    private var chooseButton: some View {
        Button(action: presenter.didTapChooseDirectory) {
            Text("Choose folder", bundle: .module)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.sousPrimary)
    }

    private var isChoosingDirectory: Binding<Bool> {
        Binding(
            get: { viewModel.isChoosingDirectory },
            set: { presenter.didChangeIsChoosingDirectory($0) }
        )
    }

    private func enter() {
        guard !isFanned else {
            return
        }

        withAnimation(reduceMotion ? Self.stillFanEntrance : Self.fanEntrance) {
            isFanned = true
        }

        withAnimation(Self.copyEntrance) {
            showsCopy = true
        }
    }
}

#Preview("Onboarding") {
    OnboardingFeatureView(
        presenter: OnboardingFeaturePresenterStub(),
        viewModel: OnboardingFeatureViewModel()
    )
}

#Preview("Onboarding, after a failure") {
    let viewModel = OnboardingFeatureViewModel()
    viewModel.failureMessage = "The folder could not be opened."

    return OnboardingFeatureView(
        presenter: OnboardingFeaturePresenterStub(),
        viewModel: viewModel
    )
}
