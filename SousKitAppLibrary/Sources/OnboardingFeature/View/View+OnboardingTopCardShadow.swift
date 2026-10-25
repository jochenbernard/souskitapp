import DesignSystem
import SwiftUI

private struct OnboardingTopCardShadowModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    private static let lightOpacity = 0.2
    private static let darkOpacity = 0.55
    private static let shadowRadius = 22.0
    private static let shadowDrop = 10.0

    @LineContainerRadius private var radius

    let isOnTop: Bool

    func body(content: Content) -> some View {
        content
            .background {
                if isOnTop {
                    // Cast by a shape, which follows the card's corners and stays cheap while the card moves.
                    RoundedRectangle(cornerRadius: radius)
                        .fill(.secondaryGroupedBackground)
                        .shadow(
                            color: .black.opacity(colorScheme == .dark ? Self.darkOpacity : Self.lightOpacity),
                            radius: Self.shadowRadius,
                            y: Self.shadowDrop
                        )
                }
            }
    }
}

extension View {
    /// Sets the card on top of the fan apart from the cards under it.
    ///
    /// - Parameter isOnTop: Whether this card lies on top of the others.
    /// - Returns: The card, standing out when it lies on top.
    func onboardingTopCardShadow(isOnTop: Bool) -> some View {
        modifier(OnboardingTopCardShadowModifier(isOnTop: isOnTop))
    }
}

#Preview("Top card shadow") {
    OnboardingShowcaseCard(OnboardingShowcaseRecipe.all[0])
        .onboardingTopCardShadow(isOnTop: true)
        .frame(width: 160.0)
        .sousPagePadding()
        .frame(maxHeight: .infinity)
        .sousPage()
}
