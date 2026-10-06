import DesignSystem
import SwiftUI

/// The button that folds the open list of timers back into their stack, there while the list is open and gone as
/// the timers fold.
struct RunningTimersCollapseButton: View, Animatable {
    // The stretch of the opening the button fades in over.
    private static let fadeRange = 0.35...0.85

    private let isOpen: Bool
    private let action: () -> Void
    private var openness: Double

    /// - Parameters:
    ///   - openness: How far the timers are open, from 0 stacked to 1 listed.
    ///   - isOpen: Whether the list is open. The button takes taps while it is, and while it is in sight as the list
    ///     folds.
    ///   - action: What folds the list back.
    init(
        openness: Double,
        isOpen: Bool,
        action: @escaping () -> Void
    ) {
        self.openness = openness
        self.isOpen = isOpen
        self.action = action
    }

    /// Whether the button is in sight, at how far the timers are open.
    ///
    /// - Parameter openness: How far the timers are open, from 0 stacked to 1 listed.
    /// - Returns: Whether any of the button shows.
    static func isVisible(openness: Double) -> Bool {
        !RunningTimersFade(openness: openness, over: fadeRange).isHidden
    }

    nonisolated var animatableData: Double {
        get { openness }
        set { openness = newValue }
    }

    // Only there while the list is open or folding away: the panel's scroll view keeps a hidden button within
    // VoiceOver's reach, so a folded stack carries none. It is invisible by the time it goes.
    var body: some View {
        if isOpen || openness > 0.0 {
            Button(action: action) {
                Label(
                    title: { Text("Collapse timers", bundle: .module) },
                    icon: { Image(systemName: "chevron.down") }
                )
            }
            .buttonStyle(.glassCircle)
            .runningTimersFade(openness: openness, over: Self.fadeRange)
            // A tap on it as it fades with the list folding still lands on it, and closes nothing more.
            .allowsHitTesting(isOpen || Self.isVisible(openness: openness))
        }
    }
}

#Preview("Running timers collapse button") {
    @Previewable @State var isOpen = true

    VStack(spacing: SousSpacing.large) {
        Toggle(isOn: $isOpen, label: { Text(verbatim: "Open") })

        RunningTimersCollapseButton(
            openness: isOpen ? 1.0 : 0.0,
            isOpen: isOpen,
            action: {}
        )
    }
    .padding()
    .animation(.runningTimers, value: isOpen)
}
