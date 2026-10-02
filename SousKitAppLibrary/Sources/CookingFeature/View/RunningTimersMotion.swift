import Observation
import SwiftUI

/// Where the running timers stand between their stack and their open list, and what the panel showing them measured.
@Observable
@MainActor
final class RunningTimersMotion {
    /// How far the timers are open, from 0 folded into their stack to 1 laid out as a list.
    var openness = 0.0

    /// How far the list is scrolled down from its top.
    var scrollOffset: CGFloat = 0.0

    /// How far up the list keeps its rows once its scrolling is undone as it folds, so they fold from where they were.
    var scrollShift: CGFloat = 0.0

    /// How far the timers are pulled past where they open or fold to, down for positive values, which they spring
    /// back from once let go.
    var rubberBand: CGFloat = 0.0

    /// How tall the stack stands, which the steps keep clear of.
    var stackHeight: CGFloat = 0.0

    nonisolated init() {}
}
