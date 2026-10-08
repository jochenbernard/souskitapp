#if DEBUG
import DesignSystem
import RecipeLibrary
import RecipeScaling
import SwiftUI

/// What only a debug build offers: test recipes in place of the folder, and a reset of the app.
struct SettingsDebugSection: View {
    private let presenter: SettingsFeaturePresenterProtocol
    private let viewModel: SettingsFeatureViewModel

    init(
        presenter: SettingsFeaturePresenterProtocol,
        viewModel: SettingsFeatureViewModel
    ) {
        self.presenter = presenter
        self.viewModel = viewModel
    }

    var body: some View {
        SettingsSection(Text("Debug", bundle: .module)) {
            Toggle(isOn: readsTestRecipes) {
                Text("Test recipes", bundle: .module)
            }
            .sousRowPadding()

            resetButton
        }
    }

    private var resetButton: some View {
        Button(role: .destructive, action: presenter.didTapResetApp) {
            Text("Reset the app", bundle: .module)
                .sousRowPadding()
                .contentShape(.rect)
        }
        .confirmationDialog(
            Text("Are you sure you want to reset the app?", bundle: .module),
            isPresented: isConfirmingReset,
            titleVisibility: .visible,
            actions: { confirmResetButton },
            message: { resetNote }
        )
    }

    private var confirmResetButton: some View {
        Button(role: .destructive, action: presenter.didConfirmReset) {
            Text("Reset the app", bundle: .module)
        }
    }

    private var resetNote: some View {
        Text(
            "The folder and the settings are forgotten and setup starts over. Recipes on disk are left alone.",
            bundle: .module
        )
    }

    private var readsTestRecipes: Binding<Bool> {
        Binding(
            get: { viewModel.recipeRepositoryKind == .mock },
            set: { presenter.didSelectRecipeRepositoryKind($0 ? .mock : .files) }
        )
    }

    private var isConfirmingReset: Binding<Bool> {
        Binding(
            get: { viewModel.isConfirmingReset },
            set: { presenter.didChangeIsConfirmingReset($0) }
        )
    }
}

#Preview("Settings debug section") {
    SettingsDebugSection(
        presenter: SettingsFeaturePresenterStub(),
        viewModel: SettingsFeatureViewModel(
            recipeRepositoryName: "Recipes",
            recipeRepositoryKind: .mock,
            appVersion: AppVersion(version: "0.3", build: "4"),
            scale: RecipeScale(target: .multiplier, value: 1.0)
        )
    )
    .sousPagePadding()
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .topLeading
    )
    .sousPage()
}
#endif
