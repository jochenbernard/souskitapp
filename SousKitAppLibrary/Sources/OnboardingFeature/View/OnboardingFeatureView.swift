import DesignSystem
import RecipeLibrary
import SwiftUI
import UniformTypeIdentifiers

struct OnboardingFeatureView: View {
    private let presenter: OnboardingFeaturePresenterProtocol
    private let viewModel: OnboardingFeatureViewModel

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // A comfortable line length for the introduction, growing with Dynamic Type.
    @ScaledMetric(relativeTo: .body) private var columnWidth = 480.0

    init(
        presenter: OnboardingFeaturePresenterProtocol,
        viewModel: OnboardingFeatureViewModel
    ) {
        self.presenter = presenter
        self.viewModel = viewModel
    }

    var body: some View {
        column
            .frame(
                maxWidth: columnWidth,
                maxHeight: isOneBlock ? nil : .infinity,
                alignment: .topLeading
            )
            .sousPagePadding()
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: isOneBlock ? .center : .topLeading
            )
            .overlay(alignment: .topTrailing) {
                debugMenu
            }
            .sousPage()
            .fileImporter(
                isPresented: isChoosingDirectory,
                allowedContentTypes: [.folder],
                onCompletion: presenter.didChooseDirectory
            )
    }

    // Where the page is wide, the setup reads as one block. On a phone the button stays in reach.
    private var isOneBlock: Bool {
        horizontalSizeClass == .regular
    }

    private var column: some View {
        VStack(alignment: .leading, spacing: SousSpacing.xxLarge) {
            introductionBlock

            actions
        }
    }

    private var introductionBlock: some View {
        VStack(alignment: .leading, spacing: SousSpacing.xxLarge) {
            lockup

            introduction
        }
        .frame(maxHeight: isOneBlock ? nil : .infinity, alignment: .leading)
    }

    private var lockup: some View {
        SousLockup(markSize: 44.0, wordmarkSize: 32.0)
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: SousSpacing.medium) {
            Text("Setup", bundle: .module)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text("Where your recipes live", bundle: .module)
                .font(.title)

            Text(
                """
                Sous reads your recipes from a folder of .sous files. Pick that folder to \
                start; you can change it later.
                """,
                bundle: .module
            )
            .foregroundStyle(.secondary)
        }
    }

    private var actions: some View {
        VStack(alignment: .leading, spacing: SousSpacing.large) {
            failureNote

            chooseButton
        }
    }

    @ViewBuilder
    private var failureNote: some View {
        if let failureMessage = viewModel.failureMessage {
            Text(failureMessage)
                .sousCallout()
        }
    }

    private var chooseButton: some View {
        Button(action: presenter.didTapChooseDirectory) {
            Text("Choose folder", bundle: .module)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.sousPrimary)
    }

    @ViewBuilder
    private var debugMenu: some View {
        #if DEBUG
        Menu(
            content: { recipeRepositoryKindPicker },
            label: {
                Label(
                    title: { Text("Debug", bundle: .module) },
                    icon: { Image(systemName: "ladybug") }
                )
                .labelStyle(.iconOnly)
                .imageScale(.large)
            }
        )
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .padding(.horizontal, SousSpacing.large)
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
    #endif

    private var isChoosingDirectory: Binding<Bool> {
        Binding(
            get: { viewModel.isChoosingDirectory },
            set: { presenter.didChangeIsChoosingDirectory($0) }
        )
    }

    // Onboarding shows while the app reads from the folder, which is yet to be picked.
    private var recipeRepositoryKind: Binding<RecipeRepositoryKind> {
        Binding(
            get: { .files },
            set: { presenter.didSelectRecipeRepositoryKind($0) }
        )
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
