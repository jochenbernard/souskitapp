import SwiftUI

/// Shows the top part of content, faded to match, so what follows moves with its lower edge.
struct DisclosureReveal: ViewModifier, Animatable {
    /// How the reveal moves, which whatever toggles it takes so the two run together.
    static let animation = Animation.spring(duration: 0.3, bounce: 0.0)

    /// The part of the content shown, from 0 for none to 1 for all of it.
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        DisclosureRevealLayout(progress: progress) {
            content
        }
        .clipped()
        .opacity(progress)
    }
}

extension View {
    /// Shows this view, or hides it from the bottom up, with what follows moving along with its lower edge.
    ///
    /// The view stays in the hierarchy while hidden.
    ///
    /// - Parameter isRevealed: Whether the view shows.
    /// - Returns: The view, shown or hidden.
    func disclosureReveal(isRevealed: Bool) -> some View {
        // Not a removal transition: a stack moves what follows before the removed view has animated out.
        modifier(DisclosureReveal(progress: isRevealed ? 1.0 : 0.0))
            .accessibilityHidden(!isRevealed)
            .allowsHitTesting(isRevealed)
    }
}

#Preview("Disclosure reveal") {
    @Previewable @State var isRevealed = true

    VStack(alignment: .leading, spacing: 0.0) {
        Button(
            action: {
                withAnimation(DisclosureReveal.animation) {
                    isRevealed.toggle()
                }
            },
            label: { Text(verbatim: "Gratin Dauphinois") }
        )

        Text(verbatim: "Rub a gratin dish with 1 clove garlic, butter it with 20 g butter, and heat the oven to 150C.")
            .sousRow()
            .padding(.top, SousSpacing.medium)
            .disclosureReveal(isRevealed: isRevealed)

        Text(verbatim: "Boeuf Bourguignon")
            .sousRow()
            .padding(.top, SousSpacing.medium)
    }
    .sousPagePadding()
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .topLeading
    )
    .sousPage()
}
