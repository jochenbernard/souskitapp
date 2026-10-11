import DesignSystem
import SwiftUI

/// Fades what a running timer shows of itself as it leaves its place or swoops to it.
///
/// Read here rather than in the row, since the leaving and the swoop change every frame of theirs: a frame then
/// updates the content's opacity alone.
private struct RunningTimerContentShare: ViewModifier {
    @Environment(\.runningTimerLeaving) private var leaving
    @Environment(\.runningTimerSwoop) private var swoop

    func body(content: Content) -> some View {
        content
            .opacity(RunningTimerLeaving.contentShare(leaving: leaving))
            .opacity(swoop.map({ RunningTimerStacking.contentShare(swooping: $0) }) ?? 1.0)
            // Gone by the swoop's end, the content passes from the swoop's fade to its place's at once, unseen.
            .animation(nil, value: swoop == nil)
    }
}

extension View {
    /// Fades what the running timer shows of itself as it leaves its place or swoops to it.
    ///
    /// - Returns: The content, fading as the timer leaves or swoops.
    func runningTimerContentShare() -> some View {
        modifier(RunningTimerContentShare())
    }
}

#Preview("Running timer content share") {
    @Previewable @State var isShown = true

    VStack(spacing: SousSpacing.large) {
        Toggle(isOn: $isShown, label: { Text(verbatim: "Shown") })

        if isShown {
            Text(verbatim: "15 min")
                .compositingGroup()
                .runningTimerContentShare()
                .padding()
                .glassEffect(.regular, in: Capsule())
                .transition(.runningTimerLeaving)
        }
    }
    .padding()
    .animation(.runningTimers, value: isShown)
}
