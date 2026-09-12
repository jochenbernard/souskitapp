import KitchenFeature
import OnboardingFeature
import SwiftUI

struct AppFeatureView: View {
    private let viewModel: AppFeatureViewModel

    init(viewModel: AppFeatureViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Group {
            switch viewModel.screen {
            case .onboarding(let onboardingFeature):
                onboardingFeature.makeView()
                    .transition(.blurReplace)

            case .kitchen(let kitchenFeature):
                kitchenFeature.makeView()
                    .transition(.blurReplace)
            }
        }
        .animation(
            .spring(duration: 0.4, bounce: 0.0),
            value: viewModel.screen.isOnboarding
        )
    }
}
