import SwiftUI

extension Color {
    /// The ground of a `List`, for the page a screen sits on. UIKit's `systemGroupedBackground`.
    public static let groupedBackground = Color(uiColor: .systemGroupedBackground)

    /// The fill of a `List` row, for a row or a card on the page. UIKit's
    /// `secondarySystemGroupedBackground`.
    public static let secondaryGroupedBackground = Color(uiColor: .secondarySystemGroupedBackground)

    /// The fill for a large control, such as a button or an input field. UIKit's
    /// `tertiarySystemFill`.
    public static let tertiaryFill = Color(uiColor: .tertiarySystemFill)

    /// The color of a border, a divider, or a shadow, translucent so what is under it shows through.
    /// UIKit's `separator`.
    ///
    /// Not repeated on `ShapeStyle`, where it would make SwiftUI's own `.separator` ambiguous. Where
    /// a style is taken, write `.separator`.
    public static let separator = Color(uiColor: .separator)
}

extension ShapeStyle where Self == Color {
    /// The ground of a `List`. See ``Color/groupedBackground``.
    public static var groupedBackground: Color { .groupedBackground }

    /// The fill of a `List` row. See ``Color/secondaryGroupedBackground``.
    public static var secondaryGroupedBackground: Color { .secondaryGroupedBackground }

    /// The fill for a large control. See ``Color/tertiaryFill``.
    public static var tertiaryFill: Color { .tertiaryFill }
}
