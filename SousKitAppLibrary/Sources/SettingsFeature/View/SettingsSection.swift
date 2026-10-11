import DesignSystem
import SwiftUI

/// A titled set of settings rows on one surface, with a note under it where one is given.
///
/// Each row takes ``SwiftUI/View/sousRowPadding()`` itself, inside a button's label where it is one, so all of it is
/// tapped.
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

            SousRowGroup {
                rows
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
