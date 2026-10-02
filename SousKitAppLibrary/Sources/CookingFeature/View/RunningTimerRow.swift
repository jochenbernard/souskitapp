import DesignSystem
import SwiftUI

/// A running timer in a box, filling as its time runs out.
struct RunningTimerRow: View {
    /// The box each timer sits in, which the timers stacked behind one take as well.
    static let shape = RoundedRectangle(cornerRadius: SousRadius.large)

    /// What taking a timer away does: stopping one that rings, or cancelling it.
    ///
    /// - Parameter isRinging: Whether the timer rings.
    /// - Returns: The action's name.
    static func cancelTitle(isRinging: Bool) -> Text {
        isRinging ? Text("Stop timer", bundle: .module) : Text("Cancel timer", bundle: .module)
    }

    // How many steps the fill grows in, about a pixel each across the widest timer.
    private static let progressSteps = 1_200.0

    private let presenter: CookingFeaturePresenterProtocol
    private let timer: RunningTimer
    private let isConfirmingCancel: Bool
    private let contentWidth: CGFloat?
    private let contentFade: RunningTimersMotionFade

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
            .clipShape(Self.shape)
            .glassEffect(.regular, in: Self.shape)
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
            label

            Spacer(minLength: 0.0)

            countdown
                .font(.title2.weight(.semibold))

            cancelButton
        }
        .padding(.horizontal, SousSpacing.large)
        .padding(.vertical, SousSpacing.medium)
        .background(alignment: .leading) {
            progress
        }
    }

    private var label: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            Text("Step \(timer.stepTimer.stepNumber)", bundle: .module)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(verbatim: timer.stepTimer.text)
        }
    }

    @ViewBuilder
    private var countdown: some View {
        if timer.isRinging {
            Text("Done", bundle: .module)
                .foregroundStyle(.accent)
        } else {
            Text(timerInterval: timer.startDate...timer.endDate, countsDown: true)
                .monospacedDigit()
        }
    }

    private var cancelButton: some View {
        Button(action: cancel) {
            Image(systemName: "xmark")
                .fontWeight(.semibold)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .accessibilityLabel(Self.cancelTitle(isRinging: timer.isRinging))
        .confirmationDialog(
            Text("Cancel the \(timer.stepTimer.text) timer from step \(timer.stepTimer.stepNumber)?", bundle: .module),
            isPresented: isConfirmingCancelBinding,
            titleVisibility: .visible,
            actions: { confirmCancelButtons }
        )
    }

    @ViewBuilder
    private var confirmCancelButtons: some View {
        Button(role: .destructive, action: presenter.didConfirmCancelTimer) {
            Text("Cancel timer", bundle: .module)
        }

        Button(role: .cancel, action: {}, label: { Text("Keep timer", bundle: .module) })
    }

    // Redrawn from the clock about as often as the fill grows by a pixel, so it keeps time with the countdown beside
    // it. Scaled rather than sized, so a redraw lays nothing out.
    private var progress: some View {
        TimelineView(.animation(minimumInterval: progressInterval, paused: isProgressPaused)) { context in
            let fraction = timer.fractionElapsed(at: context.date)

            Rectangle()
                .fill(.accent.opacity(timer.isRinging ? 0.32 : 0.2))
                .scaleEffect(x: fraction, y: 1.0, anchor: .leading)
                // A fill paused out of sight catches up at once, not on the spring that brings its timer forward.
                .animation(nil, value: fraction)
        }
    }

    private var progressInterval: Double {
        timer.stepTimer.seconds / Self.progressSteps
    }

    private var isProgressPaused: Bool {
        timer.isRinging || contentFade.isHidden
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
    VStack(spacing: SousSpacing.medium) {
        ForEach(RunningTimersPreview.timers()) { timer in
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
