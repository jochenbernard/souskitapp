import DesignSystem
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
                    .transition(.screenReplace)

            case .kitchen(let kitchenFeature):
                kitchenFeature.makeView()
                    .transition(.screenReplace)
            }
        }
        .animation(
            .spring(duration: 0.4, bounce: 0.0),
            value: viewModel.screen.isOnboarding
        )
        // A transition clips what it holds to the safe area, so the ground is drawn behind it
        // here. Left to the screens, it would draw short of the edges until the blur ended.
        .background(SousColor.background)
    }
}
