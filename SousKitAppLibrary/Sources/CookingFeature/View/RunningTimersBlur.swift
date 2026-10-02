import DesignSystem
import SwiftUI

/// Blurs what lies behind the running timers as far as their list is open.
///
/// Reads how far open the timers are on its own, so a swipe that folds them redraws the blur but leaves the view it
/// blurs as it is.
struct RunningTimersBlur: ViewModifier {
    private static let radius = 12.0

    private let motion: RunningTimersMotion
    private let isEnabled: Bool

    /// - Parameters:
    ///   - motion: Where the timers stand between their stack and their list.
    ///   - isEnabled: Whether the timers can open over the view, which they cannot beside it.
    init(
        motion: RunningTimersMotion,
        isEnabled: Bool
    ) {
        self.motion = motion
        self.isEnabled = isEnabled
    }

    func body(content: Content) -> some View {
        content
            .blur(radius: isEnabled ? Self.radius * motion.openness : 0.0)
    }
}

extension View {
    /// Blurs the view as far as the running timers over it are open.
    ///
    /// - Parameters:
    ///   - motion: Where the timers stand between their stack and their list.
    ///   - isEnabled: Whether the timers can open over the view, which they cannot beside it.
    /// - Returns: The view, blurred behind the open timers.
    func runningTimersBlur(motion: RunningTimersMotion, isEnabled: Bool) -> some View {
        modifier(RunningTimersBlur(motion: motion, isEnabled: isEnabled))
    }
}

#Preview("Running timers blur") {
    @Previewable @State var motion = RunningTimersMotion()

    VStack(spacing: SousSpacing.large) {
        Button(
            action: {
                withAnimation(.runningTimers) {
                    motion.openness = 1.0 - motion.openness
                }
            },
            label: { Text(verbatim: "Toggle") }
        )

        Text(verbatim: "Whisk the eggs with the cream.")
            .font(.title3)
            .runningTimersBlur(motion: motion, isEnabled: true)
    }
    .padding()
}
