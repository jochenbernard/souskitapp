import SwiftUI

/// The Sous button, in three emphases.
///
/// A press scales the control, and on ``Emphasis/primary`` plays a haptic.
public struct SousButtonStyle: ButtonStyle {
    /// How much weight the button carries.
    public enum Emphasis: Sendable, Hashable, CaseIterable {
        /// The one primary action on a screen: Flame, labelled in Ink.
        case primary

        /// A bordered surface, for every other button on the screen.
        case secondary

        /// No surface and no border, reading as a link.
        case quiet
    }

    /// The button, holding a press long enough to show.
    ///
    /// A tap can end within a frame of starting, leaving the scale nowhere to travel, so
    /// `isDown` outlives `configuration.isPressed` by up to ``SousButtonStyle/minimumDown``.
    private struct PressBody: View {
        let configuration: ButtonStyleConfiguration
        let emphasis: Emphasis

        @State private var isDown = false
        @State private var wentDownAt = Date.now
        @State private var release: Task<Void, Never>?

        var body: some View {
            let shape = RoundedRectangle(cornerRadius: SousRadius.medium, style: .continuous)

            configuration.label
                // Line box included: without it the control sits under the 44pt minimum target.
                .sousTextBlock(.body)
                .foregroundStyle(label)
                .padding(.horizontal, SousSpacing.large)
                .padding(.vertical, SousSpacing.medium)
                .background {
                    shape
                        .fill(background)
                        .overlay {
                            shape.strokeBorder(border, lineWidth: borderWidth)
                        }
                }
                .contentShape(shape)
                .scaleEffect(isDown ? SousButtonStyle.pressedScale : 1.0)
                .animation(SousButtonStyle.travel(isDown: isDown), value: isDown)
                .sensoryFeedback(trigger: isDown) { _, isDown in
                    guard emphasis == .primary else { return nil }

                    return isDown
                        ? .impact(flexibility: .rigid)
                        : .impact(flexibility: .rigid, intensity: SousButtonStyle.releaseIntensity)
                }
                .onChange(of: configuration.isPressed) { _, isPressed in
                    track(isPressed: isPressed)
                }
        }

        /// The border stroke, drawn only for ``Emphasis/secondary``.
        private var border: AnyShapeStyle {
            emphasis == .secondary ? AnyShapeStyle(SousColor.border) : AnyShapeStyle(.clear)
        }

        private var borderWidth: CGFloat {
            emphasis == .secondary ? 1.0 : 0.0
        }

        /// Ink for primary, the text token for secondary, the accent as text for quiet.
        private var label: AnyShapeStyle {
            switch emphasis {
            case .primary: AnyShapeStyle(SousPalette.ink)
            case .secondary: AnyShapeStyle(SousColor.text)
            case .quiet: AnyShapeStyle(SousColor.accentText)
            }
        }

        private var background: AnyShapeStyle {
            switch emphasis {
            case .primary: AnyShapeStyle(SousColor.accent)
            case .secondary: AnyShapeStyle(SousColor.surface)
            case .quiet: AnyShapeStyle(.clear)
            }
        }

        /// Follows the finger down, and back up no sooner than ``minimumDown`` after that.
        private func track(isPressed: Bool) {
            release?.cancel()

            guard !isPressed else {
                wentDownAt = .now
                isDown = true
                return
            }

            let held = Date.now.timeIntervalSince(wentDownAt)
            let remaining = SousButtonStyle.remainingDown(heldFor: held)

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

    /// How far a press shrinks the control.
    static let pressedScale = 0.97

    /// How hard the release taps, against a press at full strength.
    static let releaseIntensity = 0.4

    /// How long the control takes to reach its pressed size.
    static let pressDuration = 0.1

    /// How long it takes to come back.
    static let releaseDuration = 0.25

    /// How far the return overshoots. The press itself settles flat.
    static let releaseBounce = 0.2

    /// The shortest time a press shows for, however briefly the finger is down.
    static let minimumDown = 0.14

    private let emphasis: Emphasis

    /// The spring the control travels on, flat going down and springy coming back.
    ///
    /// - Parameter isDown: Whether the control is going down.
    /// - Returns: The animation for that direction.
    static func travel(isDown: Bool) -> Animation {
        isDown
            ? .spring(duration: pressDuration, bounce: 0.0)
            : .spring(duration: releaseDuration, bounce: releaseBounce)
    }

    /// How much longer a press shows for, after a finger down for `heldFor`.
    ///
    /// - Parameter heldFor: How long the finger was down.
    /// - Returns: The time left to hold, zero once the press has shown for long enough.
    static func remainingDown(heldFor: TimeInterval) -> TimeInterval {
        max(0.0, minimumDown - heldFor)
    }

    /// Creates a button style. Reach for ``SwiftUI/ButtonStyle/sous(_:)`` instead.
    ///
    /// - Parameter emphasis: How much weight the button carries.
    init(_ emphasis: Emphasis = .secondary) {
        self.emphasis = emphasis
    }

    public func makeBody(configuration: Configuration) -> some View {
        PressBody(configuration: configuration, emphasis: emphasis)
    }
}

extension ButtonStyle where Self == SousButtonStyle {
    /// The Sous button at a given emphasis.
    ///
    /// - Parameter emphasis: How much weight the button carries.
    /// - Returns: The button style.
    public static func sous(_ emphasis: SousButtonStyle.Emphasis) -> SousButtonStyle {
        SousButtonStyle(emphasis)
    }
}

#Preview("Buttons") {
    VStack(alignment: .leading, spacing: SousSpacing.medium) {
        Button("Boeuf Bourguignon") {
            // A preview takes no action.
        }
        .buttonStyle(.sous(.primary))

        Button("Gratin Dauphinois") {
            // A preview takes no action.
        }
        .buttonStyle(.sous(.secondary))

        Button("Vinaigrette") {
            // A preview takes no action.
        }
        .buttonStyle(.sous(.quiet))
    }
    .padding(SousSpacing.xLarge)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(SousColor.background)
}
