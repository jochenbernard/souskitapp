import DesignSystem
import RecipeLibrary
import SwiftUI

/// Where a recipe's contents are not on the device, a mark saying so on a disc in the top corner of its card.
struct RecipeAvailabilityBadge: View {
    @LineContainerRadius private var cornerRadius

    private let availability: RecipeAvailability

    init(_ availability: RecipeAvailability) {
        self.availability = availability
    }

    var body: some View {
        switch availability {
        case .downloaded:
            EmptyView()

        case .downloading:
            disc {
                // The spinner takes the symbol's size, so the disc stays the same while the recipe comes down.
                symbol
                    .hidden()
                    .overlay {
                        ProgressView()
                            .controlSize(.small)
                    }
            }
            .accessibilityLabel(Text("Downloading from iCloud", bundle: .module))

        case .notDownloaded:
            disc {
                symbol
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel(Text("In iCloud, not downloaded", bundle: .module))
        }
    }

    private var symbol: some View {
        Image(systemName: "icloud.and.arrow.down")
            .accessibilityHidden(true)
    }

    private func disc(@ViewBuilder content: () -> some View) -> some View {
        content()
            .padding(SousSpacing.xSmall)
            .background {
                Circle()
                    .fill(.regularMaterial)
                    .overlay {
                        Circle().sousBorder()
                    }
            }
            // Centered in the circle the card's corner is cut from, so the disc runs concentric with the corner.
            .frame(width: cornerRadius * 2.0, height: cornerRadius * 2.0)
            .accessibilityElement(children: .ignore)
    }
}

#Preview("Availability badges") {
    HStack(spacing: SousSpacing.medium) {
        RecipeAvailabilityBadge(.notDownloaded)

        RecipeAvailabilityBadge(.downloading)

        RecipeAvailabilityBadge(.downloaded)
    }
    .padding(SousSpacing.large)
    .background(SousPlaceholderColor.teal.color.opacity(0.18))
}
