import SwiftUI

private struct ScreenBlur: ViewModifier {
    let radius: CGFloat

    func body(content: Content) -> some View {
        content.blur(radius: radius)
    }
}

extension AnyTransition {
    /// One of the app's screens replacing another.
    static var screenReplace: AnyTransition {
        // Not `.blurReplace`, which lays the incoming screen out low and jumps its navigation bar.
        .modifier(
            active: ScreenBlur(radius: 12.0),
            identity: ScreenBlur(radius: 0.0)
        )
        .combined(with: .opacity)
    }
}
