import DesignSystem
import Foundation
import RecipeLibrary
import SwiftUI

struct KitchenFeatureView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    private let presenter: KitchenFeaturePresenterProtocol
    private let viewModel: KitchenFeatureViewModel

    init(
        presenter: KitchenFeaturePresenterProtocol,
        viewModel: KitchenFeatureViewModel
    ) {
        self.presenter = presenter
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SousSpacing.xLarge) {
                header

                recipeList
            }
            .padding(SousSpacing.xLarge)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(SousColor.background)
        .task {
            await presenter.viewDidAppear()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                presenter.didBecomeActive()
            }
        }
    }

    private var header: some View {
        Text(verbatim: viewModel.recipeDirectory.name)
            .sousTextStyle(.heading)
            .foregroundStyle(SousColor.text)
    }

    @ViewBuilder
    private var recipeList: some View {
        switch viewModel.recipeList {
        case .reading:
            readingNote

        case .recipes(let recipeFiles):
            if recipeFiles.isEmpty {
                emptyNote
            } else {
                recipeRows(recipeFiles)
            }

        case .failure(let message):
            failureNote(message)
        }
    }

    private var readingNote: some View {
        HStack(spacing: SousSpacing.medium) {
            ProgressView()
                .tint(SousColor.accent.color(in: colorScheme))

            Text("Reading the folder.")
                .sousTextStyle(.body)
                .foregroundStyle(SousColor.textMuted)
        }
    }

    private var emptyNote: some View {
        VStack(alignment: .leading, spacing: SousSpacing.small) {
            Text("Nothing here yet")
                .sousTextStyle(.body)
                .foregroundStyle(SousColor.text)

            Text("Put .sous files in this folder and they are listed here.")
                .sousTextStyle(.body)
                .foregroundStyle(SousColor.textMuted)
        }
    }

    private func recipeRows(_ recipeFiles: [RecipeFile]) -> some View {
        LazyVStack(spacing: SousSpacing.medium) {
            ForEach(recipeFiles) { recipeFile in
                recipeRow(recipeFile)
            }
        }
    }

    private func failureNote(_ message: String) -> some View {
        VStack(alignment: .leading, spacing: SousSpacing.small) {
            Text("This folder could not be read")
                .sousTextStyle(.body)
                .foregroundStyle(SousColor.accentText)

            Text(verbatim: message)
                .sousTextStyle(.body)
                .foregroundStyle(SousColor.accentText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SousSpacing.large)
        .background {
            RoundedRectangle(cornerRadius: SousRadius.medium)
                .fill(colorScheme == .dark ? SousPalette.sear : SousPalette.scorch)
        }
    }

    private func recipeRow(_ recipeFile: RecipeFile) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: SousSpacing.medium) {
            Text(verbatim: recipeFile.name)
                .sousTextStyle(.body)
                .foregroundStyle(SousColor.text)
                .frame(maxWidth: .infinity, alignment: .leading)

            availabilityBadge(recipeFile.availability)
        }
        .padding(.horizontal, SousSpacing.large)
        .padding(.vertical, SousSpacing.medium)
        .background {
            rowBackground
        }
    }

    @ViewBuilder
    private func availabilityBadge(_ availability: RecipeFileAvailability) -> some View {
        switch availability {
        case .downloaded:
            EmptyView()

        case .downloading:
            // The spinner has no text baseline to align on, so a hidden symbol lends it the row's.
            Image(systemName: "icloud.and.arrow.down")
                .accessibilityHidden(true)
                .hidden()
                .overlay {
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityLabel("Downloading from iCloud")
                }

        case .notDownloaded:
            Image(systemName: "icloud.and.arrow.down")
                .foregroundStyle(SousColor.textMuted)
                .accessibilityLabel("In iCloud, not downloaded")
        }
    }

    private var rowBackground: some View {
        let shape = RoundedRectangle(cornerRadius: SousRadius.medium)

        return shape
            .fill(SousColor.surface)
            .overlay {
                shape.strokeBorder(SousColor.border, lineWidth: 1.0)
            }
    }
}

private func previewDirectory() -> RecipeDirectory {
    RecipeDirectory(url: URL(filePath: "/Users/cook/Recipes"))
}

@MainActor
private func previewViewModel(_ recipeList: KitchenRecipeList) -> KitchenFeatureViewModel {
    let viewModel = KitchenFeatureViewModel(recipeDirectory: previewDirectory())
    viewModel.recipeList = recipeList

    return viewModel
}

private func previewRecipeFile(
    _ fileName: String,
    _ availability: RecipeFileAvailability
) -> RecipeFile {
    RecipeFile(
        url: previewDirectory().url.appending(path: fileName),
        availability: availability
    )
}

#Preview("Kitchen") {
    KitchenFeatureView(
        presenter: KitchenFeaturePresenterStub(),
        viewModel: previewViewModel(
            .recipes([
                previewRecipeFile("boeuf-bourguignon.sous", .downloaded),
                previewRecipeFile("bouillabaisse.sous", .downloaded),
                previewRecipeFile("crepes.sous", .notDownloaded),
                previewRecipeFile("gratin-dauphinois.sous", .downloading),
                previewRecipeFile("vinaigrette.sous", .downloaded)
            ])
        )
    )
}

#Preview("Kitchen, reading") {
    KitchenFeatureView(
        presenter: KitchenFeaturePresenterStub(),
        viewModel: previewViewModel(.reading)
    )
}

#Preview("Kitchen, empty") {
    KitchenFeatureView(
        presenter: KitchenFeaturePresenterStub(),
        viewModel: previewViewModel(.recipes([]))
    )
}

#Preview("Kitchen, after a failure") {
    KitchenFeatureView(
        presenter: KitchenFeaturePresenterStub(),
        viewModel: previewViewModel(.failure("The folder no longer exists."))
    )
}
