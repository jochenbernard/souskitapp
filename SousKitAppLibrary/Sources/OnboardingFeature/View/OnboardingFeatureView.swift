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
        .padding(SousSpacing.xLarge)
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
                .sousTextStyle(.eyebrow)
                .foregroundStyle(SousColor.textMuted)

            Text("Where your recipes live")
                .sousTextStyle(.title)

            Text(
                """
                Sous reads your recipes from a folder of .sous files. Pick that folder to \
                start; you can change it later.
                """
            )
            .sousTextStyle(.body)
            .foregroundStyle(SousColor.textMuted)
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
                .sousTextStyle(.body)
                .sousCallout()
        }
    }

    private var chooseButton: some View {
        Button(action: presenter.didTapChooseDirectory) {
            Text("Choose folder")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.sous(.primary))
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
