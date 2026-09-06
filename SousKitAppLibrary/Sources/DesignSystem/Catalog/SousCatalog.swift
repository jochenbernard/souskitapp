import SwiftUI

/// Every token in the design system, on one scrolling page.
public struct SousCatalog: View {
    /// One row in either of the color lists.
    private struct Swatch: Identifiable {
        let name: String
        let note: String
        let fill: AnyShapeStyle

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
            }
            .padding(SousSpacing.xLarge)
            .frame(maxWidth: 720.0, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(SousColor.background)
    }

    /// Mark and wordmark at matched sizes, the wordmark in Archivo 600.
    private var lockup: some View {
        VStack(alignment: .leading, spacing: SousSpacing.small) {
            HStack(spacing: SousSpacing.xSmall) {
                SousMark(size: 56.0)

                // Fixed, not scaled: the mark is set at the wordmark's size.
                Text(verbatim: "Sous")
                    .font(SousFontFace.archivoSemiBold.font(size: 40.0))
                    .foregroundStyle(SousColor.text)
            }
            .accessibilityElement(children: .combine)

            Text(verbatim: "Design system \u{B7} brand v1.0")
                .sousTextStyle(.eyebrow)
                .foregroundStyle(SousColor.textMuted)
        }
    }

    private var colorSection: some View {
        CatalogSection(number: "01", title: "Color") {
            VStack(alignment: .leading, spacing: SousSpacing.medium) {
                ForEach(Self.semanticTokens) { token in
                    CatalogSwatch(
                        fill: token.fill,
                        name: token.name,
                        role: token.note
                    )
                }

                Divider()
                    .overlay(SousColor.border)

                ForEach(Self.rawPalette) { entry in
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
                    .sousTextStyle(.display)

                Text("Boeuf Bourguignon")
                    .sousTextStyle(.title)

                Text("Cover the pot and braise at 150C for 3 h, until the beef gives to a fork.")
                    .sousTextStyle(.heading)

                Text(
                    """
                    Peel 1.2 kg potatoes and slice them 3 mm thick on a mandoline, then \
                    bring them to a simmer in 500 ml cream and 300 ml milk in a heavy pot \
                    with salt, black pepper, and 1/4 tsp nutmeg.
                    """
                )
                .sousTextStyle(.body)

                Text(verbatim: "1.2 kg \u{B7} 150C \u{B7} 3 h \u{B7} serves 6")
                    .sousTextStyle(.data)

                Text(verbatim: "dinner \u{B7} classic \u{B7} french")
                    .sousTextStyle(.eyebrow)
                    .foregroundStyle(SousColor.textMuted)
            }
            .foregroundStyle(SousColor.text)
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
                .foregroundStyle(SousColor.text)
            }
        }
    }

    private var spacingSection: some View {
        CatalogSection(number: "04", title: "Spacing") {
            VStack(alignment: .leading, spacing: SousSpacing.small) {
                ForEach(Self.spacingSteps, id: \.name) { step in
                    HStack(spacing: SousSpacing.medium) {
                        Rectangle()
                            .fill(SousColor.accent)
                            .frame(width: step.value, height: 8.0)

                        Text(verbatim: "\(step.name) \u{B7} \(Int(step.value))")
                            .sousTextStyle(.eyebrow)
                            .foregroundStyle(SousColor.textMuted)
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
                .buttonStyle(.sous(.primary))

                Button("Gratin Dauphinois") {
                    // The catalog shows styling, not behavior.
                }
                .buttonStyle(.sous(.secondary))

                Button("Vinaigrette") {
                    // The catalog shows styling, not behavior.
                }
                .buttonStyle(.sous(.quiet))
            }
        }
    }

    private static let semanticTokens: [Swatch] = [
        Swatch(
            name: "background",
            note: "the page ground",
            fill: AnyShapeStyle(.sousBackground)
        ),
        Swatch(
            name: "surface",
            note: "cards, sheets, inputs",
            fill: AnyShapeStyle(.sousSurface)
        ),
        Swatch(
            name: "border",
            note: "every rule and divider",
            fill: AnyShapeStyle(.sousBorder)
        ),
        Swatch(
            name: "text",
            note: "body and headings",
            fill: AnyShapeStyle(.sousText)
        ),
        Swatch(
            name: "textMuted",
            note: "secondary, captions",
            fill: AnyShapeStyle(.sousTextMuted)
        ),
        Swatch(
            name: "accent",
            note: "live, here, do",
            fill: AnyShapeStyle(.sousAccent)
        ),
        Swatch(
            name: "accentText",
            note: "links and pressed",
            fill: AnyShapeStyle(.sousAccentText)
        )
    ]

    private static let rawPalette: [Swatch] = [
        Swatch(
            name: "Ink",
            note: "#0F0F0F",
            fill: AnyShapeStyle(SousPalette.ink)
        ),
        Swatch(
            name: "Graphite",
            note: "#3A3A3A",
            fill: AnyShapeStyle(SousPalette.graphite)
        ),
        Swatch(
            name: "Steel",
            note: "#6B6B6B",
            fill: AnyShapeStyle(SousPalette.steel)
        ),
        Swatch(
            name: "Ash",
            note: "#A6A6A6",
            fill: AnyShapeStyle(SousPalette.ash)
        ),
        Swatch(
            name: "Line",
            note: "#E3E3E3",
            fill: AnyShapeStyle(SousPalette.line)
        ),
        Swatch(
            name: "Paper",
            note: "#F6F6F6",
            fill: AnyShapeStyle(SousPalette.paper)
        ),
        Swatch(
            name: "White",
            note: "#FFFFFF",
            fill: AnyShapeStyle(SousPalette.white)
        ),
        Swatch(
            name: "Flame",
            note: "#F1541C",
            fill: AnyShapeStyle(SousPalette.flame)
        ),
        Swatch(
            name: "Ember",
            note: "#B83C0C",
            fill: AnyShapeStyle(SousPalette.ember)
        ),
        Swatch(
            name: "Scorch",
            note: "#FDEBE3",
            fill: AnyShapeStyle(SousPalette.scorch)
        )
    ]

    /// Each colorway on the ground it was drawn for.
    private static let colorways: [(colorway: SousMark.Colorway, ground: Color)] = [
        (.primary, SousPalette.paper),
        (.mono, SousPalette.paper),
        (.reversed, SousPalette.ink),
        (.onFlame, SousPalette.flame),
        (.allFlame, SousPalette.paper)
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
