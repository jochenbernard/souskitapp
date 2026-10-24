import DesignSystem
import RecipeLibrary
import RecipeScaling
import SousKit
import SwiftUI

struct RecipeFeatureView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var barBottom = 0.0
    @State private var isTitleInBar = false

    @LineContainerRadius private var radius

    private let presenter: RecipeFeaturePresenterProtocol
    private let viewModel: RecipeFeatureViewModel
    private let placeholder: RecipePlaceholder
    private let cookingTransition: Namespace.ID

    // The overview's width beside the steps, growing with Dynamic Type.
    @ScaledMetric(relativeTo: .body) private var overviewWidth = 360.0

    // The cook button's width where the screen is wide, growing with Dynamic Type.
    @ScaledMetric(relativeTo: .body) private var wideCookButtonWidth = 360.0

    init(
        presenter: RecipeFeaturePresenterProtocol,
        viewModel: RecipeFeatureViewModel,
        placeholder: RecipePlaceholder,
        cookingTransition: Namespace.ID
    ) {
        self.presenter = presenter
        self.viewModel = viewModel
        self.placeholder = placeholder
        self.cookingTransition = cookingTransition
    }

    var body: some View {
        page
            .scrollEdgeEffectStyle(.soft, for: .bottom)
            .safeAreaBar(edge: .bottom) {
                cookBar
            }
            // The screen sits under the bar, so its top is where the bar ends.
            .onGeometryChange(
                for: Double.self,
                of: { $0.frame(in: .global).minY },
                action: { barBottom = $0 }
            )
            .sousPage()
            .navigationTitle(navigationTitle)
            // The header draws the title, and the bar takes it over once the header's has scrolled under it.
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    barTitle
                }
            }
            .sheet(isPresented: isScaling) {
                scaleSheet
            }
            .task {
                await presenter.viewDidAppear()
            }
    }

    private var isSideBySide: Bool {
        horizontalSizeClass == .regular
    }

    @ViewBuilder
    private var page: some View {
        if isSideBySide, case .recipe(let recipe) = viewModel.recipeContent, let metadata = bodyMetadata(of: recipe) {
            // Each column scrolls on its own, so the ingredients stay beside the steps however long the method is.
            RecipeBodyView(
                presenter: presenter,
                recipe: recipe,
                metadata: metadata,
                expandedSections: viewModel.expandedSections,
                overviewWidth: overviewWidth,
                header: header(.card)
            )
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 0.0) {
                    hero

                    content
                        .sousPagePadding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            // The hero reaches the top of the screen, and the bar's edge comes back with the title.
            .ignoresSafeArea(.container, edges: isSideBySide ? [] : .top)
            .scrollEdgeEffectHidden(!isSideBySide && !isTitleInBar, for: .top)
        }
    }

    /// The header the metadata shows, or `nil` for a recipe of neither steps nor a header, which shows a note.
    private func bodyMetadata(of recipe: ScaledRecipe) -> MetadataDisplay? {
        let metadata = RecipeDisplay.metadata(of: recipe.scaled.metadata)

        return recipe.scaled.steps.isEmpty && metadata.isEmpty ? nil : metadata
    }

    private func header(_ placement: RecipeHeaderView.Placement) -> RecipeHeaderView {
        RecipeHeaderView(
            presenter: presenter,
            viewModel: viewModel,
            placeholder: placeholder,
            title: navigationTitle,
            placement: placement,
            barBottom: barBottom,
            isTitleUnderBar: $isTitleInBar
        )
    }

    private var navigationTitle: String {
        guard case .recipe(let recipe) = viewModel.recipeContent else {
            return viewModel.recipeEntry.title
        }

        return viewModel.recipeEntry.title(of: recipe.scaled)
    }

    @ViewBuilder
    private var hero: some View {
        if !isSideBySide {
            header(.hero)
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: SousSpacing.xxLarge) {
            headerCard

            switch viewModel.recipeContent {
            case .reading:
                readingNote

            case .recipe(let recipe):
                recipeBody(recipe)

            case .failure(let message):
                failureNote(message)
            }
        }
    }

    /// The header on a card of its own, where the overview it opens stands beside the steps but is not shown.
    @ViewBuilder
    private var headerCard: some View {
        if isSideBySide {
            header(.card)
                .clipShape(.rect(cornerRadius: radius))
                .sousRowSurface()
                .frame(maxWidth: overviewWidth)
        }
    }

    private var readingNote: some View {
        SousActivityNote {
            readingMessage
        }
    }

    @ViewBuilder
    private func recipeBody(_ recipe: ScaledRecipe) -> some View {
        if let metadata = bodyMetadata(of: recipe) {
            RecipeBodyView(
                presenter: presenter,
                recipe: recipe,
                metadata: metadata,
                expandedSections: viewModel.expandedSections,
                overviewWidth: overviewWidth,
                header: nil
            )
        } else {
            emptyNote
        }
    }

    private var emptyNote: some View {
        Text("This recipe is empty.", bundle: .module)
            .foregroundStyle(.secondary)
    }

    private func failureNote(_ message: String) -> some View {
        SousFailureNote(Text("This recipe could not be read", bundle: .module), message: message)
    }

    @ViewBuilder
    private var readingMessage: some View {
        if viewModel.recipeEntry.availability == .downloaded {
            Text("Reading the recipe.", bundle: .module)
        } else {
            Text("Fetching from iCloud.", bundle: .module)
        }
    }

    @ViewBuilder
    private var cookBar: some View {
        if case .recipe(let recipe) = viewModel.recipeContent, !recipe.scaled.steps.isEmpty {
            cookButton
        }
    }

    private var cookButton: some View {
        Button(action: presenter.didTapCook) {
            Text("Start cooking", bundle: .module)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.sousPrimary)
        .matchedTransitionSource(id: RecipeFeature.cookingTransitionID, in: cookingTransition)
        .frame(maxWidth: horizontalSizeClass == .regular ? wideCookButtonWidth : .infinity)
        .sousPagePadding()
    }

    private var barTitle: some View {
        Text(verbatim: navigationTitle)
            .font(.headline)
            .lineLimit(1)
            .opacity(isTitleInBar ? 1.0 : 0.0)
            .animation(.spring(duration: 0.3), value: isTitleInBar)
            .accessibilityHidden(!isTitleInBar)
    }

    @ViewBuilder
    private var scaleSheet: some View {
        if case .recipe(let recipe) = viewModel.recipeContent {
            let scale = ScaleDisplay(recipe: recipe, text: viewModel.scaleText)

            ScaleSheet(
                Text("Scale", bundle: .module),
                presenter: presenter,
                scale: scale
            )
        }
    }

    private var isScaling: Binding<Bool> {
        Binding(
            get: { viewModel.isScaling },
            set: { presenter.didChangeIsScaling($0) }
        )
    }
}

@MainActor
private func previewViewModel(
    _ recipeContent: RecipeContent,
    availability: RecipeAvailability = .downloaded
) -> RecipeFeatureViewModel {
    let viewModel = RecipeFeatureViewModel(
        recipeEntry: RecipeEntry(
            id: "boeuf-bourguignon",
            name: "boeuf bourguignon",
            availability: availability
        ),
        folderPath: ["Recipes", "French", "Classic"]
    )
    viewModel.recipeContent = recipeContent

    return viewModel
}

private func previewRecipe(scale: RecipeScale? = nil) -> ScaledRecipe {
    let parser = SousParser()
    let recipe = parser.parseRecipe(
        """
        ---
        title: Boeuf Bourguignon
        servings: 6
        prep-time: 30 min
        cook-time: 3 h
        tags: [dinner, classic, french]
        allergens: [gluten, dairy]
        ---

        Cut @{1.2 kg} beef@ into large cubes and pat them dry. Brown @{150 g} lardons@ in a
        #casserole# for ~5 min~ until the fat runs, lift them out, then brown the beef in
        batches in the rendered fat over high heat.

        Cover the pot and braise at 150C for ~3 h~, until the beef gives to a fork.
        """
    )
    .value

    return ScaledRecipe(
        asWritten: recipe,
        parser: parser,
        scale: scale
    )
}

#Preview("Recipe") {
    @Previewable @Namespace var cookingTransition

    NavigationStack {
        RecipeFeatureView(
            presenter: RecipeFeaturePresenterStub(),
            viewModel: previewViewModel(.recipe(previewRecipe())),
            placeholder: RecipePlaceholder(symbol: "fork.knife", color: .pink),
            cookingTransition: cookingTransition
        )
    }
}

#Preview("Recipe, scaled to 12 servings") {
    @Previewable @Namespace var cookingTransition

    NavigationStack {
        RecipeFeatureView(
            presenter: RecipeFeaturePresenterStub(),
            viewModel: previewViewModel(.recipe(previewRecipe(scale: RecipeScale(target: .servings, value: 12.0)))),
            placeholder: RecipePlaceholder(symbol: "fork.knife", color: .pink),
            cookingTransition: cookingTransition
        )
    }
}

#Preview("Recipe, fetching from iCloud") {
    @Previewable @Namespace var cookingTransition

    NavigationStack {
        RecipeFeatureView(
            presenter: RecipeFeaturePresenterStub(),
            viewModel: previewViewModel(.reading, availability: .notDownloaded),
            placeholder: RecipePlaceholder(symbol: "fork.knife", color: .pink),
            cookingTransition: cookingTransition
        )
    }
}

#Preview("Recipe, after a failure") {
    @Previewable @Namespace var cookingTransition

    NavigationStack {
        RecipeFeatureView(
            presenter: RecipeFeaturePresenterStub(),
            viewModel: previewViewModel(.failure("The recipe no longer exists.")),
            placeholder: RecipePlaceholder(symbol: "fork.knife", color: .pink),
            cookingTransition: cookingTransition
        )
    }
}
