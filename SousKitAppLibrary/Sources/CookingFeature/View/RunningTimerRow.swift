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
    private let isConfirmingCancel: Bool
    private let contentWidth: CGFloat?
    private let contentFade: RunningTimersMotionFade

    @LineContainerRadius private var radius

    /// - Parameters:
    ///   - contentWidth: The width the timer lays what it shows out at, whatever the width of its box, or `nil` to
    ///     fill the box.
    ///   - contentFade: How the timer shows what it is and its time, down to only its box, as it shows stacked
    ///     behind another.
    init(
        presenter: CookingFeaturePresenterProtocol,
        timer: RunningTimer,
        isConfirmingCancel: Bool,
        contentWidth: CGFloat? = nil,
        contentFade: RunningTimersMotionFade = .disabled
    ) {
        self.presenter = presenter
        self.timer = timer
        self.isConfirmingCancel = isConfirmingCancel
        self.contentWidth = contentWidth
        self.contentFade = contentFade
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
            // The cancel button stays out of the choice, so a timer changing shape keeps its button and dialog.
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

            // Room for the timer's whole time and for Done, so a timer keeps its shape as it counts down and rings.
            ZStack(alignment: .trailing) {
                widestCountdown

                countdown
            }
        }
    }

    /// The timer's time under its label, where the two do not fit beside each other.
    private var stacked: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            label

            countdown
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
        .confirmationDialog(
            cancelQuestion,
            isPresented: isConfirmingCancelBinding,
            titleVisibility: .visible,
            actions: { confirmCancelButtons }
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

    /// The widest the timer's time gets, unseen: its whole time, or Done once it rings.
    private var widestCountdown: some View {
        ZStack {
            Text(Duration.seconds(timer.cookingTimer.seconds.rounded(.up)), format: .time(pattern: wholeTimePattern))
                .monospacedDigit()

            Text("Done", bundle: .module)
        }
        .font(.title2.weight(.semibold))
        .fixedSize()
        .hidden()
        .accessibilityHidden(true)
    }

    // Never wrapped, whatever room the timer has: its time is what a cook reads at a glance.
    private var countdown: some View {
        Group {
            if timer.isRinging {
                Text("Done", bundle: .module)
                    .foregroundStyle(.accent)
            } else {
                Text(timerInterval: timer.startDate...timer.endDate, countsDown: true)
                    .monospacedDigit()
            }
        }
        .font(.title2.weight(.semibold))
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

    private var cancelQuestion: Text {
        switch timer.cookingTimer {
        case .step(let stepTimer):
            Text("Cancel the \(stepTimer.text) timer from step \(stepTimer.stepNumber)?", bundle: .module)

        case .custom:
            Text("Cancel the custom \(timer.cookingTimer.text) timer?", bundle: .module)
        }
    }

    @ViewBuilder
    private var confirmCancelButtons: some View {
        Button(role: .destructive, action: presenter.didConfirmCancelTimer) {
            Text("Cancel timer", bundle: .module)
        }

        Button(
            role: .cancel,
            action: {},
            label: { Text("Keep timer", bundle: .module) }
        )
    }

    private var isConfirmingCancelBinding: Binding<Bool> {
        Binding(
            get: { isConfirmingCancel },
            set: { presenter.didChangeIsConfirmingCancelTimer($0) }
        )
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
                timer: timer,
                isConfirmingCancel: false
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
