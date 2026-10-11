import SwiftUI

/// Draws its content's views as rows on one surface, a divider between each two.
public struct SousRowGroup<Content: View>: View {
    private let dividerInset: CGFloat
    private let content: Content

    /// Creates a group of rows on a surface.
    ///
    /// - Parameters:
    ///   - dividerInset: How far a divider sits from the surface's edges, which is the horizontal
    ///     padding the rows themselves take.
    ///   - content: The rows, which the group draws in order.
    public init(
        dividerInset: CGFloat = SousSpacing.large,
        @ViewBuilder content: () -> Content
    ) {
        self.dividerInset = dividerInset
        self.content = content()
    }

    public var body: some View {
        Group(subviews: content) { rows in
            VStack(spacing: 0.0) {
                ForEach(rows.indices, id: \.self) { index in
                    divider(isFirst: index == rows.startIndex)

                    rows[index]
                }
            }
        }
        .sousRowSurface()
    }

    @ViewBuilder
    private func divider(isFirst: Bool) -> some View {
        if !isFirst {
            Divider()
                .padding(.horizontal, dividerInset)
        }
    }
}

#Preview("Row group") {
    SousRowGroup {
        ForEach(["Boeuf Bourguignon", "Crepes", "Gratin Dauphinois"], id: \.self) { name in
            Text(verbatim: name)
                .sousRowPadding()
        }
    }
    .sousPagePadding()
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .topLeading
    )
    .sousPage()
}
