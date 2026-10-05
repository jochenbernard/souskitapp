import DesignSystem
import SwiftUI

/// The cooking bar's background on a wide screen, shown once the steps or the timers beside them scroll under it.
///
/// Reads how far the timers are scrolled on its own, so scrolling them redraws the background alone.
struct CookingTopBarBackground: View {
    private let motion: RunningTimersMotion
    private let areStepsScrolled: Bool

    /// - Parameters:
    ///   - motion: Where the timers stand, scrolled or not.
    ///   - areStepsScrolled: Whether the steps are scrolled under the bar.
    init(
        motion: RunningTimersMotion,
        areStepsScrolled: Bool
    ) {
        self.motion = motion
        self.areStepsScrolled = areStepsScrolled
    }

    var body: some View {
        Rectangle()
            .fill(.bar)
            .overlay(alignment: .bottom) {
                Divider()
            }
            .ignoresSafeArea(edges: .top)
            .opacity(isShown ? 1.0 : 0.0)
            .animation(.spring(duration: 0.2, bounce: 0.0), value: isShown)
    }

    private var isShown: Bool {
        areStepsScrolled || motion.scrollOffset > 0.0
    }
}

#Preview("Cooking top bar background") {
    CookingTopBarBackground(
        motion: RunningTimersMotion(),
        areStepsScrolled: true
    )
    .frame(height: 60.0)
    .frame(maxHeight: .infinity, alignment: .top)
    .sousPage()
}
