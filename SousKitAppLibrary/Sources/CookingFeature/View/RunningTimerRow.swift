import DesignSystem
import SwiftUI

/// A running timer in a box, filling as its time runs out.
struct RunningTimerRow: View {
    @Environment(\.runningTimerLeaving) private var leaving
    @Environment(\.runningTimerSwoop) private var swoop

    /// The box each timer sits in, which the timers stacked behind one take as well.
    static let shape = RoundedRectangle(cornerRadius: SousRadius.large)

    // How many steps the fill grows in, about a pixel each across the widest timer.
    private static let progressSteps = 1_200.0

    private let presenter: CookingFeaturePresenterProtocol
    private let timer: RunningTimer
    private let isConfirmingCancel: Bool
    private let contentWidth: CGFloat?
    private let contentFade: RunningTimersFade

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
        contentFade: RunningTimersFade = .disabled
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
            .opacity(RunningTimerLeaving.contentShare(leaving: leaving))
            .opacity(swoop.map({ RunningTimerStacking.contentShare(swooping: $0) }) ?? 1.0)
            // Gone by the swoop's end, the content passes from the swoop's fade to its place's at once, unseen.
            .animation(nil, value: swoop == nil)
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
        .accessibilityLabel(cancelLabel)
        .confirmationDialog(
            Text("Cancel the \(timer.stepTimer.text) timer from step \(timer.stepTimer.stepNumber)?", bundle: .module),
            isPresented: isConfirmingCancelBinding,
            titleVisibility: .visible,
            actions: { confirmCancelButtons }
        )
    }

    private var cancelLabel: Text {
        timer.isRinging ? Text("Stop timer", bundle: .module) : Text("Cancel timer", bundle: .module)
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
        timer.isRinging || contentFade.isHidden || leaving > 0.0
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

private func previewTimers(endingAround date: Date) -> [RunningTimer] {
    [
        RunningTimer(
            id: UUID(),
            stepTimer: StepTimer(stepNumber: 1, text: "30 min", duration: .seconds(1_800)),
            endDate: date.addingTimeInterval(1_500),
            isRinging: false
        ),
        RunningTimer(
            id: UUID(),
            stepTimer: StepTimer(stepNumber: 3, text: "15 min", duration: .seconds(900)),
            endDate: date.addingTimeInterval(260),
            isRinging: false
        ),
        RunningTimer(
            id: UUID(),
            stepTimer: StepTimer(stepNumber: 2, text: "5-6 min", duration: .seconds(300)),
            endDate: date,
            isRinging: true
        )
    ]
}

#Preview("Running timer rows") {
    let date = Date.now

    VStack(spacing: SousSpacing.medium) {
        ForEach(previewTimers(endingAround: date)) { timer in
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
