import CookingFeature
import DesignSystem
import RecipeFeature
import RecipeLibrary
import SousKit
import SwiftUI

struct KitchenFeatureView: View {
    @Environment(\.scenePhase) private var scenePhase

    @Namespace private var cookingTransition

    private let presenter: KitchenFeaturePresenterProtocol
    private let viewModel: KitchenFeatureViewModel

    init(
        presenter: KitchenFeaturePresenterProtocol,
        viewModel: KitchenFeatureViewModel
    ) {
        self.presenter = presenter
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack(path: screenPath) {
            recipeListScreen
                .navigationDestination(for: KitchenScreen.self) { screen in
                    screenView(for: screen)
                }
        }
        // The recipe a cold start opens again is there at once, rather than pushed over a list never shown.
        .transaction(value: viewModel.isRestoring) { transaction in
            transaction.disablesAnimations = true
        }
        // Over the whole kitchen rather than pushed on it, zooming out of the button that starts it, and never swiped
        // or pinched away: its own exit is the only way out.
        .fullScreenCover(item: openCooking) { openCooking in
            openCooking.feature.makeView()
                .navigationTransition(.zoom(sourceID: RecipeFeature.cookingTransitionID, in: cookingTransition))
                .interactiveDismissDisabled()
        }
        // Cooking a cold start opens again is there at once, rather than zooming out of a button it never left.
        .transaction(value: viewModel.openCooking?.id) { transaction in
            if viewModel.openCooking?.isResumed == true {
                transaction.disablesAnimations = true
            }
        }
    }

    private var recipeListScreen: some View {
        ScrollView {
            // A blank page, rather than a list the restored recipe covers a moment later.
            if !viewModel.isRestoring {
                recipeList
                    .sousPagePadding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .sousPage()
        .navigationTitle(viewModel.recipeRepositoryName)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                debugMenu
            }
        }
        .toolbarVisibility(viewModel.isRestoring ? .hidden : .automatic, for: .navigationBar)
        .task {
            await presenter.viewDidAppear()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task {
                    await presenter.didBecomeActive()
                }
            }
        }
    }

    @ViewBuilder
    private var recipeList: some View {
        switch viewModel.recipeList {
        case .reading:
            readingNote

        case .recipes(let recipeEntries):
            if recipeEntries.isEmpty {
                emptyNote
            } else {
                recipeRows(recipeEntries)
            }

        case .failure(let message):
            failureNote(message)
        }
    }

    private var readingNote: some View {
        SousActivityNote {
            Text("Reading the folder.", bundle: .module)
        }
    }

    private var emptyNote: some View {
        VStack(alignment: .leading, spacing: SousSpacing.small) {
            Text("Nothing here yet", bundle: .module)

            Text("Put .sous files in this folder and they are listed here.", bundle: .module)
                .foregroundStyle(.secondary)
        }
    }

    private func recipeRows(_ recipeEntries: [RecipeEntry]) -> some View {
        LazyVStack(spacing: SousSpacing.medium) {
            ForEach(recipeEntries) { recipeEntry in
                NavigationLink(value: KitchenScreen.recipe(recipeEntry)) {
                    recipeRow(recipeEntry)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func failureNote(_ message: String) -> some View {
        SousFailureNote(Text("This folder could not be read", bundle: .module), message: message)
    }

    private func recipeRow(_ recipeEntry: RecipeEntry) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: SousSpacing.medium) {
            Text(verbatim: recipeEntry.name)
                .frame(maxWidth: .infinity, alignment: .leading)

            availabilityBadge(recipeEntry.availability)
        }
        .sousRow()
    }

    @ViewBuilder
    private func availabilityBadge(_ availability: RecipeAvailability) -> some View {
        switch availability {
        case .downloaded:
            EmptyView()

        case .downloading:
            // The spinner has no text baseline to align on, so a hidden symbol lends it the row's.
            Image(systemName: "icloud.and.arrow.down")
                .accessibilityHidden(true)
                .hidden()
                .overlay {
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityLabel(Text("Downloading from iCloud", bundle: .module))
                }

        case .notDownloaded:
            Image(systemName: "icloud.and.arrow.down")
                .foregroundStyle(.secondary)
                .accessibilityLabel(Text("In iCloud, not downloaded", bundle: .module))
        }
    }

    @ViewBuilder
    private var debugMenu: some View {
        #if DEBUG
        Menu(
            content: {
                recipeRepositoryKindPicker

                resetButton
            },
            label: {
                Label(
                    title: { Text("Debug", bundle: .module) },
                    icon: { Image(systemName: "ladybug") }
                )
            }
        )
        .confirmationDialog(
            Text("Are you sure you want to reset the app?", bundle: .module),
            isPresented: isConfirmingReset,
            titleVisibility: .visible,
            actions: { confirmResetButton },
            message: { resetNote }
        )
        #endif
    }

    #if DEBUG
    private var recipeRepositoryKindPicker: some View {
        Picker(
            selection: recipeRepositoryKind,
            content: {
                Label(
                    title: { Text("Folder", bundle: .module) },
                    icon: { Image(systemName: "folder") }
                )
                .tag(RecipeRepositoryKind.files)

                Label(
                    title: { Text("Mock recipes", bundle: .module) },
                    icon: { Image(systemName: "testtube.2") }
                )
                .tag(RecipeRepositoryKind.mock)
            },
            label: { Text("Recipes", bundle: .module) }
        )
    }

    private var resetButton: some View {
        Button(role: .destructive, action: presenter.didTapReset) {
            Label(
                title: { Text("Reset the app", bundle: .module) },
                icon: { Image(systemName: "arrow.counterclockwise") }
            )
        }
    }

    private var confirmResetButton: some View {
        Button(role: .destructive, action: presenter.didConfirmReset) {
            Text("Reset the app", bundle: .module)
        }
    }

    private var resetNote: some View {
        Text(
            "The folder is forgotten and setup starts over. Recipes on disk are left alone.",
            bundle: .module
        )
    }
    #endif

    @ViewBuilder
    private func screenView(for screen: KitchenScreen) -> some View {
        switch screen {
        case .recipe(let recipeEntry):
            recipeScreen(for: recipeEntry)
        }
    }

    @ViewBuilder
    private func recipeScreen(for recipeEntry: RecipeEntry) -> some View {
        if let openRecipe = viewModel.openRecipe, openRecipe.recipeEntry == recipeEntry {
            openRecipe.feature.makeView(cookingTransition: cookingTransition)
        }
    }

    private var recipeRepositoryKind: Binding<RecipeRepositoryKind> {
        Binding(
            get: { viewModel.recipeRepositoryKind },
            set: { presenter.didSelectRecipeRepositoryKind($0) }
        )
    }

    private var isConfirmingReset: Binding<Bool> {
        Binding(
            get: { viewModel.isConfirmingReset },
            set: { presenter.didChangeIsConfirmingReset($0) }
        )
    }

    private var openCooking: Binding<OpenCooking?> {
        Binding(
            get: { viewModel.openCooking },
            set: { openCooking in
                if openCooking == nil {
                    presenter.didDismissCooking()
                }
            }
        )
    }

    private var screenPath: Binding<[KitchenScreen]> {
        Binding(
            get: { viewModel.screenPath },
            set: { presenter.didChangeScreenPath($0) }
        )
    }
}

@MainActor
private func previewViewModel(
    _ recipeList: KitchenRecipeList,
    isRestoring: Bool = false
) -> KitchenFeatureViewModel {
    let viewModel = KitchenFeatureViewModel(
        recipeRepositoryName: "Recipes",
        recipeRepositoryKind: .files
    )
    viewModel.recipeList = recipeList
    viewModel.isRestoring = isRestoring

    return viewModel
}

private func previewRecipeEntry(
    _ name: String,
    _ availability: RecipeAvailability
) -> RecipeEntry {
    RecipeEntry(
        id: name,
        name: name,
        availability: availability
    )
}

#Preview("Kitchen") {
    KitchenFeatureView(
        presenter: KitchenFeaturePresenterStub(),
        viewModel: previewViewModel(
            .recipes([
                previewRecipeEntry("boeuf bourguignon", .downloaded),
                previewRecipeEntry("bouillabaisse", .downloaded),
                previewRecipeEntry("crepes", .notDownloaded),
                previewRecipeEntry("gratin dauphinois", .downloading),
                previewRecipeEntry("vinaigrette", .downloaded)
            ])
        )
    )
}

#Preview("Kitchen, reading") {
    KitchenFeatureView(
        presenter: KitchenFeaturePresenterStub(),
        viewModel: previewViewModel(.reading)
    )
}

#Preview("Kitchen, restoring") {
    KitchenFeatureView(
        presenter: KitchenFeaturePresenterStub(),
        viewModel: previewViewModel(.reading, isRestoring: true)
    )
}

#Preview("Kitchen, empty") {
    KitchenFeatureView(
        presenter: KitchenFeaturePresenterStub(),
        viewModel: previewViewModel(.recipes([]))
    )
}

#Preview("Kitchen, after a failure") {
    KitchenFeatureView(
        presenter: KitchenFeaturePresenterStub(),
        viewModel: previewViewModel(.failure("The folder no longer exists."))
    )
}
