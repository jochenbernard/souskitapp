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
        screen
            .transition(.screenReplace)
            // A kitchen replacing another is a view of its own, so it reads its own repository from the start.
            .id(viewModel.screen.identity)
            .animation(
                .spring(duration: 0.4, bounce: 0.0),
                value: viewModel.screen.identity
            )
            // A blurred screen fades out at the perimeter, letting the window's own background
            // through, so the ground is drawn behind the transition rather than by the screens.
            .sousPage()
    }

    @ViewBuilder
    private var screen: some View {
        switch viewModel.screen {
        case .onboarding(let onboardingFeature):
            onboardingFeature.makeView()

        case .kitchen(let kitchenFeature, _):
            kitchenFeature.makeView()
        }
    }
}
