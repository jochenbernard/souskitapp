import DesignSystem
import SwiftUI

/// The cards standing in for a folder's while it is read, as many as fill a page.
struct PlaceholderCardGrid: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // Never shown, since the cards are drawn as placeholders: they only give the bars their lengths.
    private static let titles = [
        "Boeuf Bourguignon",
        "Quiche Lorraine",
        "Crepes",
        "Gratin Dauphinois",
        "Madeleines",
        "Bouillabaisse",
        "Moules Marinieres",
        "Croque Monsieur",
        "Vinaigrette",
        "Brioche"
    ]
    private static let details = ["3 h 30 min", "1 h 20 min", "35 min", "2 h", "1 h", "1 h 30 min"]

    private let minimumColumnWidth: CGFloat

    /// - Parameter minimumColumnWidth: The narrowest a column may be, as the cards it stands in for take it.
    init(minimumColumnWidth: CGFloat) {
        self.minimumColumnWidth = minimumColumnWidth
    }

    var body: some View {
        RecipeCardGrid(minimumColumnWidth: minimumColumnWidth, spacing: SousSpacing.medium) {
            ForEach(0..<cardCount, id: \.self) { index in
                KitchenCard(
                    title: Self.titles[index % Self.titles.count],
                    picture: { Color.tertiaryFill },
                    detail: { Text(verbatim: Self.details[index % Self.details.count]) }
                )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Reading the folder.", bundle: .module))
    }

    // Enough rows to fill an iPhone's page, or an iPad's in either orientation.
    private var cardCount: Int {
        horizontalSizeClass == .regular ? 24 : 10
    }
}

#Preview("Placeholder cards") {
    ScrollView {
        PlaceholderCardGrid(minimumColumnWidth: 160.0)
            .sousPagePadding()
    }
    .environment(\.isSousLoading, true)
    .sousPage()
}
