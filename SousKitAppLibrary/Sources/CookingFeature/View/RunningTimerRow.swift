import DesignSystem
import SwiftUI

/// A running timer in a box, filling as its time runs out.
struct RunningTimerRow: View {
    /// What taking a timer away does: stopping one that rings, or cancelling it.
    ///
    /// - Parameter isRinging: Whether the timer rings.
    /// - Returns: The action's name.
    static func cancelTitle(isRinging: Bool) -> Text {
        isRinging ? Text("Stop timer", bundle: .module) : Text("Cancel timer", bundle: .module)
    }

    private let presenter: CookingFeaturePresenterProtocol
    private let timer: RunningTimer
    private let contentWidth: CGFloat?
    private let contentFade: RunningTimersMotionFade
    private let onCancelButtonFrameChange: ((CGRect) -> Void)?

    @LineContainerRadius private var radius

    /// - Parameters:
    ///   - contentWidth: The width the timer lays what it shows out at, whatever the width of its box, or `nil` to
    ///     fill the box.
    ///   - contentFade: How the timer shows what it is and its time, down to only its box, as it shows stacked
    ///     behind another.
    ///   - onCancelButtonFrameChange: Reports where the cancel button stands on the screen, which the question
    ///     whether to cancel the timer points at.
    init(
        presenter: CookingFeaturePresenterProtocol,
        timer: RunningTimer,
        contentWidth: CGFloat? = nil,
        contentFade: RunningTimersMotionFade = .disabled,
        onCancelButtonFrameChange: ((CGRect) -> Void)? = nil
    ) {
        self.presenter = presenter
        self.timer = timer
        self.contentWidth = contentWidth
        self.contentFade = contentFade
        self.onCancelButtonFrameChange = onCancelButtonFrameChange
    }

    var body: some View {
        framedContent
            .compositingGroup()
            .modifier(contentFade)
            .runningTimerContentShare()
            .clipShape(shape)
            .glassEffect(.regular, in: shape)
    }

    /// The box the timer sits in.
    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: radius)
    }

    @ViewBuilder
    private var framedContent: some View {
        if let contentWidth {
            RunningTimerContentFrame(width: contentWidth) {
                content
            }
        } else {
            content
        }
    }

    private var content: some View {
        HStack(spacing: SousSpacing.medium) {
            // The cancel button stays out of the choice, so a timer changing shape keeps its button.
            ViewThatFits(in: .horizontal) {
                sideBySide

                stacked
            }

            cancelButton
        }
        .padding(.horizontal, SousSpacing.large)
        .padding(.vertical, SousSpacing.medium)
        .background(alignment: .leading) {
            RunningTimerProgress(timer: timer, contentFade: contentFade)
        }
    }

    /// The timer's label beside its time, where every line of the label fits whole there.
    private var sideBySide: some View {
        HStack(spacing: SousSpacing.medium) {
            label
                .fixedSize()
                .frame(maxWidth: .infinity, alignment: .leading)

            countdown(reservingWidest: true)
        }
    }

    /// The timer's time under its label, where the two do not fit beside each other.
    private var stacked: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            label

            countdown(reservingWidest: false)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cancelButton: some View {
        Button(action: cancel) {
            Image(systemName: "xmark")
                .fontWeight(.semibold)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel(Self.cancelTitle(isRinging: timer.isRinging))
        // Read after the timer's time, which lies lower than the button where it is under the label.
        .accessibilitySortPriority(-1.0)
        .onGeometryChange(
            for: CGRect.self,
            of: { $0.frame(in: .global) },
            action: { frame in onCancelButtonFrameChange?(frame) }
        )
    }

    private var label: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            source
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(verbatim: timer.cookingTimer.text)
        }
    }

    /// The timer's time, or Done once it rings.
    ///
    /// - Parameter reservingWidest: Whether it takes the room of the timer's whole time and of Done all along.
    private func countdown(reservingWidest: Bool) -> some View {
        ZStack(alignment: .trailing) {
            if reservingWidest {
                // So a timer keeps its shape as it counts down and rings.
                Group {
                    Text(
                        Duration.seconds(timer.cookingTimer.seconds.rounded(.up)),
                        format: .time(pattern: wholeTimePattern)
                    )
                    .monospacedDigit()

                    Text("Done", bundle: .module)
                }
                .hidden()
                .accessibilityHidden(true)
            }

            if timer.isRinging {
                Text("Done", bundle: .module)
                    .foregroundStyle(.accent)
            } else {
                Text(timerInterval: timer.startDate...timer.endDate, countsDown: true)
                    .monospacedDigit()
            }
        }
        .font(.title2.weight(.semibold))
        // Never wrapped, whatever room the timer has: its time is what a cook reads at a glance.
        .fixedSize()
    }

    /// Where the timer comes from: the step naming it, or the cook.
    private var source: Text {
        switch timer.cookingTimer {
        case .step(let stepTimer): Text("Step \(stepTimer.stepNumber)", bundle: .module)
        case .custom: Text("Custom", bundle: .module)
        }
    }

    /// How the timer's countdown shows its whole time, with hours only for a timer of an hour or more.
    private var wholeTimePattern: Duration.TimeFormatStyle.Pattern {
        timer.cookingTimer.seconds >= 3_600.0 ? .hourMinuteSecond : .minuteSecond
    }

    private func cancel() {
        presenter.didTapCancelTimer(timer)
    }
}

#Preview("Running timer rows") {
    let longTimer = RunningTimer(
        id: UUID(),
        cookingTimer: .custom(.seconds(9_000)),
        endDate: .now.addingTimeInterval(8_100.0),
        isRinging: false
    )

    VStack(spacing: SousSpacing.medium) {
        ForEach(RunningTimersPreview.timers() + [longTimer]) { timer in
            RunningTimerRow(
                presenter: CookingFeaturePresenterStub(),
                timer: timer
            )
        }
    }
    .sousPagePadding()
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .topLeading
    )
    .sousPage()
}
