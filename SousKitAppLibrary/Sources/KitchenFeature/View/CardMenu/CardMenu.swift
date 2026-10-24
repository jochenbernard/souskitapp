import CoreGraphics
import SwiftUI

/// A card's context menu: its choices, what opens the card, and a preview of what it opens, which a tap opens too.
struct CardMenu {
    /// The choices after Open.
    let items: [CardMenuItem]

    let open: @MainActor () -> Void

    /// What the card opens at a glance, made as the menu opens.
    let preview: @MainActor () -> AnyView

    /// The card's corner radius, which its lift into the menu keeps.
    let cornerRadius: CGFloat
}
