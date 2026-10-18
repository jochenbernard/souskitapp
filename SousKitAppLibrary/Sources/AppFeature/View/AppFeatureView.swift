import DesignSystem
import KitchenFeature
import OnboardingFeature
import SettingsFeature
import SwiftUI

struct AppFeatureView: View {
    @Environment(\.scenePhase) private var scenePhase

    private let presenter: AppFeaturePresenterProtocol
    private let viewModel: AppFeatureViewModel

    init(
        presenter: AppFeaturePresenterProtocol,
        viewModel: AppFeatureViewModel
    ) {
        self.presenter = presenter
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
            // Over the screens rather than on the kitchen, so the settings stay open while the kitchen is replaced.
            .sheet(item: openSettings) { openSettings in
                openSettings.feature.makeView()
            }
            // Settings a cold start opens again are there at once, rather than sliding up over a list never left.
            .transaction(value: viewModel.openSettings?.id) { transaction in
                if viewModel.openSettings?.isRestored == true {
                    transaction.disablesAnimations = true
                }
            }
            .onAppear(perform: presenter.viewDidAppear)
            .onChange(of: scenePhase) { _, phase in
                if phase == .background {
                    presenter.didEnterBackground()
                }
            }
    }

    @ViewBuilder
    private var screen: some View {
        switch viewModel.screen {
        case .onboarding(let onboardingFeature):
            onboardingFeature.makeView()

        case .kitchen(let kitchenFeature, _):
            NavigationStack(path: kitchenFeature.path) {
                kitchenFeature.makeView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            SettingsButton(action: presenter.didTapSettings)
                        }
                    }
            }
            // The recipe a cold start opens again is there at once, rather than pushed over a list never shown.
            .transaction(value: kitchenFeature.isRestoring) { transaction in
                transaction.disablesAnimations = true
            }
        }
    }

    private var openSettings: Binding<OpenSettings?> {
        Binding(
            get: { viewModel.openSettings },
            set: { openSettings in
                if openSettings == nil {
                    presenter.didDismissSettings()
                }
            }
        )
    }
}
