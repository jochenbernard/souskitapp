import SwiftUI

private struct SousLoadingPlaceholderModifier: ViewModifier {
    @Environment(\.isSousLoading) private var isLoading
    @Environment(\.accessibilityReduceMotion) private var reducesMotion

    private static let breathing = Animation.spring(duration: 1.1, bounce: 0.0).repeatForever(autoreverses: true)
    private static let dimmedOpacity = 0.4

    @State private var isDimmed = false

    func body(content: Content) -> some View {
        if isLoading {
            content
                .redacted(reason: .placeholder)
                // Scoped to the opacity, so the repeating animation never takes hold of the layout.
                .animation(Self.breathing) { placeholder in
                    placeholder
                        .opacity(isDimmed && !reducesMotion ? Self.dimmedOpacity : 1.0)
                }
                .onAppear {
                    isDimmed = true
                }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        } else {
            content
        }
    }
}

extension EnvironmentValues {
    /// Whether the views under it stand in for content still being read.
    @Entry public var isSousLoading = false
}

extension View {
    /// Draws the view as a placeholder for content still being read where `isSousLoading` is true, and as itself
    /// elsewhere.
    ///
    /// A placeholder keeps the view's shape, cannot be touched, and is hidden from assistive technologies, so the
    /// screen announces the wait itself. Mark the views that hold what is being read, and leave what is known before,
    /// such as a section's heading, unmarked.
    ///
    /// - Returns: The view, as a placeholder while it stands in for content.
    public func sousLoadingPlaceholder() -> some View {
        modifier(SousLoadingPlaceholderModifier())
    }
}

#Preview("Loading placeholders") {
    VStack(alignment: .leading, spacing: SousSpacing.small) {
        Text(verbatim: "Ingredients")
            .foregroundStyle(.accent)
            .padding(.horizontal, SousSpacing.large)

        SousRowGroup {
            ForEach(["butter", "flour", "salt"], id: \.self) { name in
                Text(verbatim: name)
                    .sousLoadingPlaceholder()
                    .sousRowPadding()
            }
        }
    }
    .environment(\.isSousLoading, true)
    .sousPagePadding()
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .topLeading
    )
    .sousPage()
}
