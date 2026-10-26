import SwiftUI

private struct SousLoadingArrivalModifier: ViewModifier {
    // Content that arrives this soon replaces the placeholders at once, since a fade would only flash them.
    private static let quickRead = Duration.milliseconds(500)
    private static let arrival = Animation.spring(duration: 0.35, bounce: 0.0)

    let isLoading: Bool

    @State private var isReadSlow = false

    func body(content: Content) -> some View {
        content
            .animation(isReadSlow ? Self.arrival : nil, value: isLoading)
            .task(id: isLoading) {
                guard isLoading else {
                    return
                }

                isReadSlow = false
                try? await Task.sleep(for: Self.quickRead)
                isReadSlow = !Task.isCancelled
            }
    }
}

extension View {
    /// Brings in what changes once content is read as `SousLoadingStack` brings in its content, so the two arrive
    /// together.
    ///
    /// - Parameter isLoading: Whether the content is still being read.
    /// - Returns: The view, changing with the content.
    public func sousLoadingArrival(isLoading: Bool) -> some View {
        modifier(SousLoadingArrivalModifier(isLoading: isLoading))
    }
}

#Preview("Loading arrival") {
    @Previewable @State var isLoading = true

    VStack(alignment: .leading, spacing: SousSpacing.large) {
        Toggle(isOn: $isLoading) {
            Text(verbatim: "Loading")
        }

        ZStack {
            if !isLoading {
                Text(verbatim: "Start cooking")
                    .sousRow()
            }
        }
        .sousLoadingArrival(isLoading: isLoading)
    }
    .sousPagePadding()
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .topLeading
    )
    .sousPage()
}
