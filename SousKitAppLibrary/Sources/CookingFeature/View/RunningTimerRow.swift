import DesignSystem
import SwiftUI

/// A running timer as a row whose background fills as its time runs out.
struct RunningTimerRow: View {
    private let presenter: CookingFeaturePresenterProtocol
    private let timer: RunningTimer
    private let isConfirmingCancel: Bool

    init(
        presenter: CookingFeaturePresenterProtocol,
        timer: RunningTimer,
        isConfirmingCancel: Bool
    ) {
        self.presenter = presenter
        self.timer = timer
        self.isConfirmingCancel = isConfirmingCancel
    }

    var body: some View {
        HStack(spacing: SousSpacing.medium) {
            label

            Spacer(minLength: 0.0)

            countdown

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
                .font(.title2.weight(.semibold))
                .foregroundStyle(.accent)
        } else {
            Text(timerInterval: timer.startDate...timer.endDate, countsDown: true)
                .font(.title2.weight(.semibold))
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

    // Redrawn every frame from the clock, so the fill keeps time with the countdown beside it.
    private var progress: some View {
        TimelineView(.animation(paused: timer.isRinging)) { context in
            GeometryReader { proxy in
                Rectangle()
                    .fill(.accent.opacity(timer.isRinging ? 0.32 : 0.2))
                    .frame(width: proxy.size.width * timer.fractionElapsed(at: context.date))
            }
        }
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
            .sousSurface(RoundedRectangle(cornerRadius: SousRadius.large))
            .clipShape(RoundedRectangle(cornerRadius: SousRadius.large))
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
