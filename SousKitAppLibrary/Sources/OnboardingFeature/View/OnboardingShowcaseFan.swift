import DesignSystem
import SwiftUI

/// The showcase recipes as the kitchen's cards, fanned out the way a folder's card stacks its recipes.
struct OnboardingShowcaseFan: View {
    private static let shadowOpacity = 0.1
    private static let shadowRadius = 14.0
    private static let shadowDrop = 6.0

    private let cardWidths: ClosedRange<Double>
    private let isFanned: Bool

    /// - Parameters:
    ///   - cardWidths: The narrowest and the widest a card can be.
    ///   - isFanned: Whether the cards are fanned out, or lie on one another.
    init(cardWidths: ClosedRange<Double>, isFanned: Bool) {
        self.cardWidths = cardWidths
        self.isFanned = isFanned
    }

    var body: some View {
        OnboardingFanLayout(cardWidths: cardWidths, isFanned: isFanned) {
            ForEach(Array(OnboardingShowcaseRecipe.all.enumerated()), id: \.element.id) { index, recipe in
                let position = OnboardingFanLayout.position(ofCardAt: index, of: OnboardingShowcaseRecipe.all.count)

                OnboardingShowcaseCard(recipe)
                    .shadow(
                        color: .black.opacity(Self.shadowOpacity),
                        radius: Self.shadowRadius,
                        y: Self.shadowDrop
                    )
                    .rotationEffect(.degrees(isFanned ? position * OnboardingFanLayout.angle : 0.0), anchor: .bottom)
                    // The middle card on top, the others tucked under it.
                    .zIndex(-abs(position))
            }
        }
        // A picture of the kitchen rather than text to read, so it keeps one size.
        .dynamicTypeSize(...DynamicTypeSize.large)
        .accessibilityHidden(true)
    }
}

#Preview("Showcase fan") {
    VStack(spacing: SousSpacing.section) {
        OnboardingShowcaseFan(cardWidths: 120.0...160.0, isFanned: true)

        OnboardingShowcaseFan(cardWidths: 120.0...160.0, isFanned: false)
    }
    .sousPagePadding()
    .frame(maxHeight: .infinity)
    .sousPage()
}
