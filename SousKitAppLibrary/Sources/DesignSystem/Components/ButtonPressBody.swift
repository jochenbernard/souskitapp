import SwiftUI

/// The body of a Sous button, holding a press long enough to show.
///
/// A tap can end within a frame of starting, leaving a press nowhere to travel, so the `isDown`
/// passed to `content` outlives `isPressed` by up to ``ButtonPress/minimumDown``.
struct ButtonPressBody<Content: View>: View {
    let isPressed: Bool
    @ViewBuilder let content: (Bool) -> Content

    @State private var isDown = false
    @State private var wentDownAt = Date.now
    @State private var release: Task<Void, Never>?

    var body: some View {
        content(isDown)
            .onChange(of: isPressed) { _, isPressed in
                track(isPressed: isPressed)
            }
    }

    /// Follows the finger down, and back up no sooner than ``ButtonPress/minimumDown`` after that.
    private func track(isPressed: Bool) {
        release?.cancel()

        guard !isPressed else {
            wentDownAt = .now
            isDown = true
            return
        }

        let held = Date.now.timeIntervalSince(wentDownAt)
        let remaining = ButtonPress.remainingDown(heldFor: held)

        guard remaining > 0.0 else {
            isDown = false
            return
        }

        release = Task {
            try? await Task.sleep(for: .seconds(remaining))

            guard !Task.isCancelled else { return }

            isDown = false
        }
    }
}

#Preview("Press hold") {
    @Previewable @State var isPressed = false

    VStack(spacing: SousSpacing.xLarge) {
        ButtonPressBody(isPressed: isPressed) { isDown in
            Capsule()
                .fill(SousColor.accent)
                .frame(width: 220.0, height: 56.0)
                .sousPressScale(isDown: isDown)
        }

        Toggle(isOn: $isPressed) {
            Text(verbatim: "isPressed")
                .sousTextStyle(.data)
        }
        .foregroundStyle(SousColor.text)
    }
    .padding(SousSpacing.xLarge)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SousColor.background)
}
