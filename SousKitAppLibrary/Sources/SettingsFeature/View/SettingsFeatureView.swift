import DesignSystem
import RecipeLibrary
import RecipeScaling
import SwiftUI
import UniformTypeIdentifiers

struct SettingsFeatureView: View {
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
        NavigationStack {
            ScrollView {
                sections
                    .sousPagePadding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .sousPage()
            .navigationTitle(Text("Settings", bundle: .module))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    doneButton
                }
            }
        }
        .presentationDragIndicator(.hidden)
        .fileImporter(
            isPresented: isChoosingDirectory,
            allowedContentTypes: [.folder],
            onCompletion: presenter.didChooseDirectory
        )
        .sheet(isPresented: isScaling) {
            scaleSheet
        }
    }

    private var sections: some View {
        VStack(alignment: .leading, spacing: SousSpacing.xLarge) {
            directorySection

            scalingSection

            debugSection

            versionNote
        }
        // The folder's note comes and goes when a debug build moves the kitchen under the open settings.
        .animation(.spring(duration: 0.4, bounce: 0.0), value: viewModel.recipeRepositoryKind)
    }

    private var doneButton: some View {
        Button(role: .confirm, action: presenter.didTapDone)
    }

    private var scaleSheet: some View {
        ScaleSheet(
            Text("Open recipes at", bundle: .module),
            presenter: presenter,
            scale: ScaleDisplay(preferred: viewModel.scale, text: viewModel.scaleText)
        )
    }

    private var directorySection: some View {
        VStack(alignment: .leading, spacing: SousSpacing.medium) {
            SettingsSection(Text("Folder", bundle: .module), footer: directoryNote) {
                directoryRow
            }

            failureNote
        }
    }

    private var scalingSection: some View {
        SettingsSection(Text("Scaling", bundle: .module), footer: scalingNote) {
            ScaleRow(
                Text("Open recipes at", bundle: .module),
                scale: viewModel.scale,
                action: presenter.didTapScale
            )
        }
    }

    @ViewBuilder
    private var debugSection: some View {
        #if DEBUG
        SettingsDebugSection(
            presenter: presenter,
            viewModel: viewModel
        )
        #endif
    }

    private var versionNote: some View {
        Text("Version \(viewModel.appVersion.version) (\(viewModel.appVersion.build))", bundle: .module)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .monospacedDigit()
            .frame(maxWidth: .infinity)
    }

    private var directoryNote: Text? {
        switch viewModel.recipeRepositoryKind {
        case .files: Text("Sous reads the .sous files in this folder.", bundle: .module)
        case .mock: nil
        }
    }

    private var directoryRow: some View {
        // The button goes under the folder's name where the two do not fit side by side.
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: SousSpacing.medium) {
                directoryLabel
                    .frame(maxWidth: .infinity, alignment: .leading)

                changeDirectoryButton
            }

            VStack(alignment: .leading, spacing: SousSpacing.small) {
                directoryLabel

                changeDirectoryButton
            }
        }
        .sousRowPadding()
    }

    private var directoryLabel: some View {
        Label(
            title: { Text(verbatim: viewModel.recipeRepositoryName) },
            icon: { Image(systemName: "folder") }
        )
    }

    private var changeDirectoryButton: some View {
        Button(action: presenter.didTapChangeDirectory) {
            Text("Change", bundle: .module)
                .foregroundStyle(.accent)
        }
        .buttonStyle(.sousBare)
    }

    @ViewBuilder
    private var failureNote: some View {
        if let failureMessage = viewModel.failureMessage {
            Text(failureMessage)
                .sousCallout()
        }
    }

    private var scalingNote: Text? {
        switch viewModel.scale.target {
        case .servings: Text("Recipes that declare no servings open as written.", bundle: .module)
        case .multiplier, .yield: nil
        }
    }

    private var isChoosingDirectory: Binding<Bool> {
        Binding(
            get: { viewModel.isChoosingDirectory },
            set: { presenter.didChangeIsChoosingDirectory($0) }
        )
    }

    private var isScaling: Binding<Bool> {
        Binding(
            get: { viewModel.isScaling },
            set: { presenter.didChangeIsScaling($0) }
        )
    }
}

@MainActor
private func previewSettingsView(
    _ scale: RecipeScale,
    failureMessage: String? = nil
) -> SettingsFeatureView {
    let viewModel = SettingsFeatureViewModel(
        recipeRepositoryName: "Recipes",
        recipeRepositoryKind: .files,
        appVersion: AppVersion(version: "0.3", build: "4"),
        scale: scale
    )
    viewModel.failureMessage = failureMessage

    return SettingsFeatureView(
        presenter: SettingsFeaturePresenterStub(),
        viewModel: viewModel
    )
}

#Preview("Settings") {
    previewSettingsView(RecipeScale(target: .multiplier, value: 1.0))
}

#Preview("Settings, on servings") {
    previewSettingsView(RecipeScale(target: .servings, value: 4.0))
}

#Preview("Settings, after a failure") {
    previewSettingsView(
        RecipeScale(target: .multiplier, value: 1.0),
        failureMessage: "The folder could not be opened."
    )
}
