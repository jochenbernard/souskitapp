import SwiftUI

extension Color {
    /// The ground a screen sits on.
    public static let groupedBackground = Color(uiColor: .systemGroupedBackground)

    /// The fill of a row or a card on the page.
    public static let secondaryGroupedBackground = Color(uiColor: .secondarySystemGroupedBackground)

    /// The fill for a large control, such as a button or an input field, and for a chip.
    public static let tertiaryFill = Color(uiColor: .tertiarySystemFill)

    /// The color of a border, a divider, or a shadow.
    ///
    /// Not repeated on `ShapeStyle`, where it would make SwiftUI's own `.separator` ambiguous. Where
    /// a style is taken, write `.separator`.
    public static let separator = Color(uiColor: .separator)
}

extension ShapeStyle where Self == Color {
    /// The ground a screen sits on. See ``Color/groupedBackground``.
    public static var groupedBackground: Color { .groupedBackground }

    /// The fill of a row or a card. See ``Color/secondaryGroupedBackground``.
    public static var secondaryGroupedBackground: Color { .secondaryGroupedBackground }

    /// The fill for a large control or a chip. See ``Color/tertiaryFill``.
    public static var tertiaryFill: Color { .tertiaryFill }
}
