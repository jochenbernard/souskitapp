import SwiftUI

/// A sheet that sets one thing, under a bar holding its title and actions.
///
/// The sheet sits low, as tall as what it holds, so the screen it opens over stays in view above it.
public struct SousSheet<Content: View, Actions: ToolbarContent>: View {
    private let title: Text
    private let content: Content
    private let actions: Actions

    // What the sheet holds, measured as it is laid out, so content that wraps still fits.
    @State private var contentHeight: Double?

    // The toolbar, which keeps its height at every text size and cannot be measured before the detent applies.
    private let barHeight = 70.0

    // About as tall as the content comes out, for the layouts before it is measured.
    @ScaledMetric(relativeTo: .body) private var estimatedContentHeight = 200.0

    /// Creates the sheet.
    ///
    /// - Parameters:
    ///   - title: What the sheet is called.
    ///   - content: What the sheet holds, stacked from the top down.
    ///   - actions: The actions in the sheet's bar.
    public init(
        _ title: Text,
        @ViewBuilder content: () -> Content,
        @ToolbarContentBuilder actions: () -> Actions
    ) {
        self.title = title
        self.content = content()
        self.actions = actions()
    }

    public var body: some View {
        NavigationStack {
            measuredContent
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    actions
                }
        }
        .presentationDetents([.height(sheetHeight)])
        .presentationDragIndicator(.hidden)
    }

    private var measuredContent: some View {
        VStack(spacing: SousSpacing.xLarge) {
            content
        }
        .sousPagePadding()
        // As tall as the content needs whatever the detent offers, so the sheet grows where a line starts to wrap.
        .fixedSize(horizontal: false, vertical: true)
        // Only once the content sits under the bar: earlier layouts are at other widths, where it wraps differently.
        .onGeometryChange(
            for: Double?.self,
            of: { $0.safeAreaInsets.top > 0.0 ? $0.size.height : nil },
            action: { contentHeight = $0 ?? contentHeight }
        )
        // No taller than the detent offers, so content it cannot hold runs off the bottom and not up under the bar.
        .frame(
            maxWidth: .infinity,
            minHeight: 0.0,
            maxHeight: .infinity,
            alignment: .top
        )
        // The sheet's own ground, so the page behind it is read through nothing but the sheet.
        .sousPage()
    }

    private var sheetHeight: Double {
        (contentHeight ?? estimatedContentHeight) + barHeight
    }
}

#Preview("Sheet") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            SousSheet(
                Text(verbatim: "Scale"),
                content: {
                    Text(verbatim: "12 servings")
                        .font(.largeTitle)
                },
                actions: {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(role: .confirm, action: {})
                    }
                }
            )
        }
}
