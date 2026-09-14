import SwiftUI

/// Every token in the design system, on one scrolling page.
public struct SousCatalog: View {
    /// One row in either of the color lists.
    private struct Swatch: Identifiable {
        let name: String
        let note: String
        let fill: Color

        var id: String { name }
    }

    /// Creates the catalog.
    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SousSpacing.xLarge) {
                lockup

                colorSection

                typeSection

                markSection

                spacingSection

                buttonSection

                containerSection
            }
            .padding(.horizontal, SousSpacing.large)
            .padding(.vertical, SousSpacing.small)
            .frame(maxWidth: 720.0, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .sousPage()
    }

    private var lockup: some View {
        VStack(alignment: .leading, spacing: SousSpacing.small) {
            SousLockup(markSize: 56.0, wordmarkSize: 40.0)

            Text(verbatim: "Design system")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var colorSection: some View {
        CatalogSection(number: "01", title: "Color") {
            VStack(alignment: .leading, spacing: SousSpacing.medium) {
                ForEach(Self.accentColors) { entry in
                    CatalogSwatch(
                        fill: entry.fill,
                        name: entry.name,
                        role: entry.note
                    )
                }

                Divider()

                ForEach(Self.systemColors) { entry in
                    CatalogSwatch(
                        fill: entry.fill,
                        name: entry.name,
                        role: entry.note
                    )
                }
            }
        }
    }

    private var typeSection: some View {
        CatalogSection(number: "02", title: "Type") {
            VStack(alignment: .leading, spacing: SousSpacing.large) {
                Text("Madeleines")
                    .font(.largeTitle)

                Text("Boeuf Bourguignon")
                    .font(.title)

                Text("Cover the pot and braise at 150C for 3 h, until the beef gives to a fork.")
                    .font(.title3)

                Text(
                    """
                    Peel 1.2 kg potatoes and slice them 3 mm thick on a mandoline, then \
                    bring them to a simmer in 500 ml cream and 300 ml milk in a heavy pot \
                    with salt, black pepper, and 1/4 tsp nutmeg.
                    """
                )
                .font(.body)

                Text(verbatim: "1.2 kg \u{B7} 150C \u{B7} 3 h \u{B7} serves 6")
                    .font(.subheadline)

                Text(verbatim: "dinner \u{B7} classic \u{B7} french")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var markSection: some View {
        CatalogSection(number: "03", title: "The mark") {
            VStack(alignment: .leading, spacing: SousSpacing.large) {
                HStack(spacing: SousSpacing.small) {
                    ForEach(Self.colorways, id: \.colorway) { entry in
                        SousMark(entry.colorway, size: 64.0)
                            .background(entry.ground)
                    }
                }

                HStack(alignment: .bottom, spacing: SousSpacing.small) {
                    ForEach([80.0, 56.0, 40.0, 32.0, 24.0, 20.0, 16.0], id: \.self) { size in
                        SousMark(.inherited, size: size)
                    }
                }
            }
        }
    }

    private var spacingSection: some View {
        CatalogSection(number: "04", title: "Spacing") {
            VStack(alignment: .leading, spacing: SousSpacing.small) {
                ForEach(Self.spacingSteps, id: \.name) { step in
                    HStack(spacing: SousSpacing.medium) {
                        Rectangle()
                            .fill(.accent)
                            .frame(width: step.value, height: 8.0)

                        Text(verbatim: "\(step.name) \u{B7} \(Int(step.value))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var buttonSection: some View {
        CatalogSection(number: "05", title: "Buttons") {
            VStack(alignment: .leading, spacing: SousSpacing.medium) {
                Button("Boeuf Bourguignon") {
                    // The catalog shows styling, not behavior.
                }
                .buttonStyle(.sousPrimary)

                Button("Gratin Dauphinois") {
                    // The catalog shows styling, not behavior.
                }
                .buttonStyle(.sousSecondary)

                Button("Vinaigrette") {
                    // The catalog shows styling, not behavior.
                }
                .buttonStyle(.sousQuiet)
            }
        }
    }

    private var containerSection: some View {
        CatalogSection(number: "06", title: "Containers") {
            CatalogContainers()
        }
    }

    private static let accentColors: [Swatch] = [
        Swatch(
            name: "accent",
            note: "live, here, do",
            fill: .accent
        ),
        Swatch(
            name: "quaternaryAccentFill",
            note: "callouts",
            fill: .quaternaryAccentFill
        )
    ]

    private static let systemColors: [Swatch] = [
        Swatch(
            name: "groupedBackground",
            note: "the page ground",
            fill: .groupedBackground
        ),
        Swatch(
            name: "secondaryGroupedBackground",
            note: "rows and cards",
            fill: .secondaryGroupedBackground
        ),
        Swatch(
            name: "tertiaryFill",
            note: "secondary buttons",
            fill: .tertiaryFill
        ),
        Swatch(
            name: "separator",
            note: "borders and shadows",
            fill: .separator
        ),
        Swatch(
            name: "primary",
            note: "body and headings",
            fill: .primary
        ),
        Swatch(
            name: "secondary",
            note: "captions and metadata",
            fill: .secondary
        )
    ]

    /// Each colorway on the ground it was drawn for.
    private static let colorways: [(colorway: SousMark.Colorway, ground: Color)] = [
        (.primary, .white),
        (.mono, .white),
        (.reversed, .black),
        (.onAccent, .accent),
        (.allAccent, .white)
    ]

    private static let spacingSteps: [(name: String, value: CGFloat)] = [
        ("hairline", SousSpacing.hairline),
        ("xSmall", SousSpacing.xSmall),
        ("small", SousSpacing.small),
        ("medium", SousSpacing.medium),
        ("large", SousSpacing.large),
        ("xLarge", SousSpacing.xLarge),
        ("xxLarge", SousSpacing.xxLarge),
        ("section", SousSpacing.section),
        ("page", SousSpacing.page)
    ]
}

#Preview("Light") {
    SousCatalog()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SousCatalog()
        .preferredColorScheme(.dark)
}
