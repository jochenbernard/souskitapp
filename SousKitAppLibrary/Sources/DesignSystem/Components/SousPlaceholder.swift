import SwiftUI

/// What stands in for a recipe's picture where it has none: a symbol in the recipe's color, on a wash of it.
public struct SousPlaceholder: View {
    private static let washOpacity = 0.18

    private let symbol: String
    private let color: SousPlaceholderColor
    private let symbolFont: Font
    private let symbolInsets: EdgeInsets

    /// Creates a placeholder.
    ///
    /// - Parameters:
    ///   - symbol: The name of the SF Symbol standing in for the recipe.
    ///   - color: The recipe's color.
    ///   - symbolFont: The font the symbol is sized by, larger where the placeholder is.
    ///   - symbolInsets: The room the symbol is centered in, inset from the placeholder's edges, such as above a
    ///     title over its bottom.
    public init(
        symbol: String,
        color: SousPlaceholderColor,
        symbolFont: Font = .title,
        symbolInsets: EdgeInsets = EdgeInsets()
    ) {
        self.symbol = symbol
        self.color = color
        self.symbolFont = symbolFont
        self.symbolInsets = symbolInsets
    }

    public var body: some View {
        color.color
            .opacity(Self.washOpacity)
            .overlay {
                Image(systemName: symbol)
                    .font(symbolFont)
                    .foregroundStyle(color.color)
                    .padding(symbolInsets)
            }
            .accessibilityHidden(true)
    }
}

#Preview("Placeholders") {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80.0), spacing: SousSpacing.small)], spacing: SousSpacing.small) {
        ForEach(SousPlaceholderColor.allCases, id: \.self) { color in
            SousPlaceholder(symbol: "fork.knife", color: color)
                .frame(height: 60.0)
        }
    }
    .sousPagePadding()
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .top
    )
    .sousPage()
}
