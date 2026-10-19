import DesignSystem
import SwiftUI

/// What a card shows where its recipe has no picture: a symbol in the recipe's color, on a wash of it.
struct RecipeCardPlaceholder: View {
    private static let washOpacity = 0.18

    private let symbol: String
    private let color: SousPlaceholderColor

    init(
        symbol: String,
        color: SousPlaceholderColor
    ) {
        self.symbol = symbol
        self.color = color
    }

    var body: some View {
        color.color
            .opacity(Self.washOpacity)
            .overlay {
                Image(systemName: symbol)
                    .font(.title)
                    .foregroundStyle(color.color)
            }
            .accessibilityHidden(true)
    }
}

#Preview("Placeholders") {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80.0), spacing: SousSpacing.small)], spacing: SousSpacing.small) {
        ForEach(SousPlaceholderColor.allCases, id: \.self) { color in
            RecipeCardPlaceholder(symbol: "fork.knife", color: color)
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
