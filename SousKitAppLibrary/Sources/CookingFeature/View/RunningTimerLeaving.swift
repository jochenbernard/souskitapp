import DesignSystem
import SwiftUI

/// Takes a running timer out of its place: its box shrinks and fades on the timers' spring, and what it shows of
/// itself goes first, before its box lies over another timer's.
struct RunningTimerLeaving: ViewModifier, Animatable {
    // How far the box shrinks, and the share of the way at which the timer no longer shows what it is.
    private static let shrink = 0.2
    private static let contentGone = 0.2

    var animatableData: Double

    /// - Parameter amount: How far the timer is gone, from 0 in its place to 1 away.
    nonisolated init(_ amount: Double) {
        self.animatableData = amount
    }

    /// How much of what a timer shows of itself is left at a point of its leaving.
    ///
    /// - Parameter amount: How far the timer is gone, from 0 in its place to 1 away.
    /// - Returns: The share of its content that shows, from 1 down to 0.
    static func contentShare(leaving amount: Double) -> Double {
        (1.0 - amount / contentGone).clamped(to: 0.0...1.0)
    }

    func body(content: Content) -> some View {
        content
            .opacity(1.0 - animatableData)
            .scaleEffect(1.0 - Self.shrink * animatableData)
            .environment(\.runningTimerLeaving, animatableData)
    }
}

extension EnvironmentValues {
    /// How far a running timer is gone from its place at this frame, from 0 in its place to 1 away.
    @Entry var runningTimerLeaving = 0.0
}

extension AnyTransition {
    /// A running timer leaving its place.
    static var runningTimerLeaving: AnyTransition {
        .modifier(active: RunningTimerLeaving(1.0), identity: RunningTimerLeaving(0.0))
    }
}

#Preview("Running timer leaving") {
    @Previewable @State var isShown = true

    VStack(spacing: SousSpacing.large) {
        Toggle(isOn: $isShown, label: { Text(verbatim: "Shown") })

        if isShown {
            RunningTimerRow(
                presenter: CookingFeaturePresenterStub(),
                timer: RunningTimersPreview.timers()[1]
            )
            .transition(.runningTimerLeaving)
        }
    }
    .padding()
    .animation(.runningTimers, value: isShown)
}
