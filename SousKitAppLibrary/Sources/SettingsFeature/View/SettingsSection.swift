import DesignSystem
import SwiftUI

/// A titled set of settings rows, with a note under it where one is given.
///
/// One row stands as a row of its own, as the recipes on home do, and more share one box, as on a recipe. Each row
/// takes ``SwiftUI/View/sousRowPadding()`` itself, inside a button's label where it is one, so all of it is tapped.
struct SettingsSection<Rows: View>: View {
    private let title: Text
    private let footer: Text?
    private let rows: Rows

    init(
        _ title: Text,
        footer: Text? = nil,
        @ViewBuilder rows: () -> Rows
    ) {
        self.title = title
        self.footer = footer
        self.rows = rows()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SousSpacing.small) {
            title
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, SousSpacing.large)
                .accessibilityAddTraits(.isHeader)

            Group(subviews: rows) { subviews in
                if subviews.count == 1 {
                    subviews
                        .sousRowSurface()
                } else {
                    SousRowGroup {
                        subviews
                    }
                }
            }

            footerNote
        }
    }

    @ViewBuilder
    private var footerNote: some View {
        if let footer {
            footer
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, SousSpacing.large)
        }
    }
}

#Preview("Settings section") {
    SettingsSection(Text(verbatim: "Folder"), footer: Text(verbatim: "Sous reads the .sous files in this folder.")) {
        Text(verbatim: "Recipes")
            .sousRowPadding()

        Text(verbatim: "Brioche")
            .sousRowPadding()
    }
    .sousPagePadding()
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .topLeading
    )
    .sousPage()
}
