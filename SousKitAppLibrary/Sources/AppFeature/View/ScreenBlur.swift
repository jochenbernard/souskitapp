import SwiftUI

/// Blurs a screen on its way in or out.
private struct ScreenBlur: ViewModifier {
    let radius: CGFloat

    func body(content: Content) -> some View {
        content.blur(radius: radius)
    }
}

extension AnyTransition {
    /// A screen blurring and fading into the one it replaces.
    ///
    /// Blurred here rather than by `.blurReplace`, which lays the incoming screen out away from
    /// the window: a navigation bar comes in 10pt low and jumps as the transition ends.
    static var screenReplace: AnyTransition {
        .modifier(
            active: ScreenBlur(radius: 12.0),
            identity: ScreenBlur(radius: 0.0)
        )
        .combined(with: .opacity)
    }
}
