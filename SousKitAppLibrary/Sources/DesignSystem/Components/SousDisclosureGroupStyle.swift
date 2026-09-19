import SwiftUI

/// A disclosure group whose header lines up with content drawn on a surface.
public struct SousDisclosureGroupStyle: DisclosureGroupStyle {
    public func makeBody(configuration: Configuration) -> some View {
        // The automatic style clips its content, a surface's shadow included, and cannot inset its chevron.
        VStack(alignment: .leading, spacing: 0.0) {
            header(configuration)

            VStack(alignment: .leading, spacing: SousSpacing.small) {
                configuration.content
            }
            // Inside the reveal, so the gap closes with the content.
            .padding(.top, SousSpacing.small)
            .disclosureReveal(isRevealed: configuration.isExpanded)
        }
    }

    private func header(_ configuration: Configuration) -> some View {
        Button(
            action: {
                withAnimation(DisclosureReveal.animation) {
                    configuration.isExpanded.toggle()
                }
            },
            label: {
                HStack(spacing: SousSpacing.small) {
                    configuration.label
                        .foregroundStyle(.accent)

                    Spacer(minLength: 0.0)

                    chevron(isExpanded: configuration.isExpanded)
                }
                .padding(.horizontal, SousSpacing.large)
                .contentShape(.rect)
            }
        )
        .accessibilityValue(expandedValue(isExpanded: configuration.isExpanded))
    }

    private func chevron(isExpanded: Bool) -> some View {
        Image(systemName: "chevron.right")
            .imageScale(.small)
            .fontWeight(.semibold)
            // `.primary` inside a button label resolves to the button's tint.
            .foregroundStyle(.primary)
            .rotationEffect(.degrees(isExpanded ? 90.0 : 0.0))
            .accessibilityHidden(true)
    }

    private func expandedValue(isExpanded: Bool) -> Text {
        isExpanded
            ? Text("Expanded", bundle: .module)
            : Text("Collapsed", bundle: .module)
    }
}

extension DisclosureGroupStyle where Self == SousDisclosureGroupStyle {
    /// A disclosure group lined up with content on a surface. See ``SousDisclosureGroupStyle``.
    public static var sous: SousDisclosureGroupStyle {
        SousDisclosureGroupStyle()
    }
}

#Preview("Disclosure group") {
    @Previewable @State var isExpanded = true

    DisclosureGroup(
        isExpanded: $isExpanded,
        content: {
            Text(verbatim: "Cover the pot and braise at 150C for 3 h, until the beef gives to a fork.")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(SousSpacing.large)
                .sousSurface(RoundedRectangle(cornerRadius: SousRadius.large))
        },
        label: { Text(verbatim: "Boeuf Bourguignon") }
    )
    .disclosureGroupStyle(.sous)
    .sousPagePadding()
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .topLeading
    )
    .sousPage()
}
