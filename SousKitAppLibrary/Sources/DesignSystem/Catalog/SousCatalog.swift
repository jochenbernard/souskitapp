import SwiftUI

/// Every token in the design system, on one scrolling page.
public struct SousCatalog: View {
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
            .sousPagePadding()
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
                ForEach(Self.accentColors, id: \.name) { swatch in
                    swatch
                }

                Divider()

                ForEach(Self.systemColors, id: \.name) { swatch in
                    swatch
                }
            }
        }
    }

    private var typeSection: some View {
        CatalogSection(number: "02", title: "Type") {
            VStack(alignment: .leading, spacing: SousSpacing.large) {
                Text(verbatim: "Madeleines")
                    .font(.largeTitle)

                Text(verbatim: "Boeuf Bourguignon")
                    .font(.title)

                Text(verbatim: "Cover the pot and braise at 150C for 3 h, until the beef gives to a fork.")
                    .font(.title3)

                Text(
                    verbatim: """
                    Peel 1.2 kg potatoes and slice them 3 mm thick on a mandoline, then \
                    bring them to a simmer in 500 ml cream and 300 ml milk in a heavy pot \
                    with salt, black pepper, and 1/4 tsp nutmeg.
                    """
                )

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
                Button(action: {}, label: { Text(verbatim: "Boeuf Bourguignon") })
                    .buttonStyle(.sousPrimary)

                Button(action: {}, label: { Text(verbatim: "Gratin Dauphinois") })
                    .buttonStyle(.sousSecondary)

                Button(action: {}, label: { Text(verbatim: "Vinaigrette") })
                    .buttonStyle(.sousQuiet)

                bareButton

                chipButtons
            }
        }
    }

    private var bareButton: some View {
        Button(
            action: {},
            label: {
                Text(verbatim: "1")
                    .monospacedDigit()
                    .frame(width: 32.0, height: 32.0)
                    .background(.tertiaryFill, in: Circle())
            }
        )
        .buttonStyle(.sousBare)
    }

    private var chipButtons: some View {
        SousFlowLayout(spacing: SousSpacing.small) {
            ForEach(["servings", "kg", "crepes"], id: \.self) { name in
                Button(action: {}, label: { Text(verbatim: name) })
                    .buttonStyle(.sousChip(isSelected: name == "servings"))
            }
        }
    }

    private var containerSection: some View {
        CatalogSection(number: "06", title: "Containers") {
            CatalogContainers()
        }
    }

    private static let accentColors: [CatalogSwatch] = [
        CatalogSwatch(
            fill: .accent,
            name: "accent",
            role: "live, here, do"
        ),
        CatalogSwatch(
            fill: .quaternaryAccentFill,
            name: "quaternaryAccentFill",
            role: "callouts, a chosen chip"
        )
    ]

    private static let systemColors: [CatalogSwatch] = [
        CatalogSwatch(
            fill: .groupedBackground,
            name: "groupedBackground",
            role: "the page ground"
        ),
        CatalogSwatch(
            fill: .secondaryGroupedBackground,
            name: "secondaryGroupedBackground",
            role: "rows and cards"
        ),
        CatalogSwatch(
            fill: .tertiaryFill,
            name: "tertiaryFill",
            role: "secondary buttons"
        ),
        CatalogSwatch(
            fill: .separator,
            name: "separator",
            role: "borders"
        ),
        CatalogSwatch(
            fill: .primary,
            name: "primary",
            role: "body and headings"
        ),
        CatalogSwatch(
            fill: .secondary,
            name: "secondary",
            role: "captions and metadata"
        )
    ]

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
