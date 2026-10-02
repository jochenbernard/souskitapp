import DesignSystem
import SwiftUI

/// Lays a running timer over or under the others by its place in the stack: the soonest on top, each one further
/// down under the one above it, and a timer swooping to its place over them until halfway, where it is clear of them.
struct RunningTimerStacking: ViewModifier, Animatable {
    // Where along the swoop the timer passes behind the others, and starts no longer showing what it is.
    private static let halfway = 0.5

    var animatableData: Double

    private let depth: Int
    private let isSwooping: Bool

    /// - Parameters:
    ///   - depth: How many timers lie before this one.
    ///   - swoop: How far the timer is on its swoop to its place, from 0 in front to 1 in its place, or `nil` for a
    ///     timer in its place.
    nonisolated init(depth: Int, swoop: Double?) {
        self.animatableData = swoop ?? 0.0
        self.depth = depth
        self.isSwooping = swoop != nil
    }

    /// How much of what a timer shows of itself is left at a point of its swoop: all of it until it passes behind the
    /// others, and none once it is in its place.
    ///
    /// - Parameter swoop: How far the timer is on its swoop, from 0 in front to 1 in its place.
    /// - Returns: The share of its content that shows, from 1 down to 0.
    static func contentShare(swooping swoop: Double) -> Double {
        min(1.0, max(0.0, (1.0 - swoop) / (1.0 - halfway)))
    }

    func body(content: Content) -> some View {
        content
            .environment(\.runningTimerSwoop, isSwooping ? animatableData : nil)
            .zIndex(isSwooping && animatableData < Self.halfway ? 1.0 : -Double(depth))
    }
}

extension EnvironmentValues {
    /// How far a running timer is on its swoop to its place at this frame, from 0 in front to 1 in its place, or `nil`
    /// for a timer in its place.
    @Entry var runningTimerSwoop: Double?
}

extension View {
    /// Lays the running timer over or under the others by its place in the stack.
    ///
    /// - Parameters:
    ///   - depth: How many timers lie before this one.
    ///   - swoop: How far the timer is on its swoop to its place, from 0 in front to 1 in its place, or `nil` for a
    ///     timer in its place.
    /// - Returns: The timer, over or under the others.
    func runningTimerStacking(depth: Int, swoop: Double?) -> some View {
        modifier(RunningTimerStacking(depth: depth, swoop: swoop))
    }
}

#Preview("Running timer stacking") {
    @Previewable @State var swoop = 0.0

    VStack(spacing: SousSpacing.large) {
        Slider(value: $swoop)

        ZStack {
            RoundedRectangle(cornerRadius: SousRadius.large)
                .fill(.accent)
                .frame(width: 200.0, height: 60.0)
                .runningTimerStacking(depth: 0, swoop: nil)

            RoundedRectangle(cornerRadius: SousRadius.large)
                .fill(.secondary)
                .frame(width: 160.0, height: 60.0)
                .offset(y: 20.0)
                .runningTimerStacking(depth: 1, swoop: swoop)
        }
    }
    .padding()
}
