import SwiftUI

/// Content still being read, with placeholders shaped like it standing in until it arrives.
///
/// The content lands where the placeholders were, so build them from the content's own views. Within them,
/// `isSousLoading` is true, which draws every view marked with `sousLoadingPlaceholder()` as a placeholder.
public struct SousLoadingStack<Content: View, Placeholders: View>: View {
    private static var arrival: Animation {
        .spring(duration: 0.5, bounce: 0.0)
    }

    private let isLoading: Bool
    private let content: Content
    private let placeholders: Placeholders

    /// Creates a stack.
    ///
    /// - Parameters:
    ///   - isLoading: Whether the content is still being read.
    ///   - content: The content, which may be empty while it is read.
    ///   - placeholders: What stands in for the content while it is read.
    public init(
        isLoading: Bool,
        @ViewBuilder content: () -> Content,
        @ViewBuilder placeholders: () -> Placeholders
    ) {
        self.isLoading = isLoading
        self.content = content()
        self.placeholders = placeholders()
    }

    public var body: some View {
        // Over the content, which stands in place at once while they fade from above it, so nothing it shares with
        // them dims on the way.
        ZStack(alignment: .topLeading) {
            content

            // Animated apart from the content, which arrives at once.
            ZStack(alignment: .topLeading) {
                if isLoading {
                    placeholders
                        .environment(\.isSousLoading, true)
                        .transition(.asymmetric(insertion: .identity, removal: .opacity))
                }
            }
            .animation(Self.arrival, value: isLoading)
        }
    }
}

#Preview("Loading stack") {
    @Previewable @State var isLoading = true

    VStack(alignment: .leading, spacing: SousSpacing.large) {
        Toggle(isOn: $isLoading) {
            Text(verbatim: "Loading")
        }

        SousLoadingStack(
            isLoading: isLoading,
            content: {
                if !isLoading {
                    Text(verbatim: "Rub a gratin dish with 1 clove garlic.")
                        .sousRow()
                }
            },
            placeholders: {
                Text(verbatim: "Rub a gratin dish with 1 clove garlic.")
                    .sousLoadingPlaceholder()
                    .sousRow()
            }
        )
    }
    .sousPagePadding()
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .topLeading
    )
    .sousPage()
}
