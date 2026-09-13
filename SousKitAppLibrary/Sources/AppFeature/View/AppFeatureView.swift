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
        // A blurred screen fades out at the perimeter, letting the window's own white through,
        // so the ground is drawn behind the transition rather than by the screens it fades.
        .background(SousColor.background)
    }
}
