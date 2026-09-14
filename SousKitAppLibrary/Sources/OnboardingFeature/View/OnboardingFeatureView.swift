import DesignSystem
import SwiftUI
import UniformTypeIdentifiers

struct OnboardingFeatureView: View {
    private let presenter: OnboardingFeaturePresenterProtocol
    private let viewModel: OnboardingFeatureViewModel

    init(
        presenter: OnboardingFeaturePresenterProtocol,
        viewModel: OnboardingFeatureViewModel
    ) {
        self.presenter = presenter
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SousSpacing.xxLarge) {
            lockup

            introduction

            Spacer(minLength: 0.0)

            actions
        }
        .padding(.horizontal, SousSpacing.large)
        .padding(.vertical, SousSpacing.small)
        .frame(
            maxWidth: .infinity,
            alignment: .topLeading
        )
        .sousPage()
        .fileImporter(
            isPresented: isChoosingDirectory,
            allowedContentTypes: [.folder],
            onCompletion: presenter.didChooseDirectory
        )
    }

    private var lockup: some View {
        SousLockup(markSize: 44.0, wordmarkSize: 32.0)
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: SousSpacing.medium) {
            Text("Setup")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text("Where your recipes live")
                .font(.title)

            Text(
                """
                Sous reads your recipes from a folder of .sous files. Pick that folder to \
                start; you can change it later.
                """
            )
            .font(.body)
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
                .font(.body)
                .sousCallout()
        }
    }

    private var chooseButton: some View {
        Button(action: presenter.didTapChooseDirectory) {
            Text("Choose folder")
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
