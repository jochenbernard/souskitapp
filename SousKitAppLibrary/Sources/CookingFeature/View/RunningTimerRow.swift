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
            label

            Spacer(minLength: 0.0)

            countdown
                .font(.title2.weight(.semibold))

            cancelButton
        }
        .padding(.horizontal, SousSpacing.large)
        .padding(.vertical, SousSpacing.medium)
        .background(alignment: .leading) {
            RunningTimerProgress(timer: timer, contentFade: contentFade)
        }
    }

    private var label: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            source
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(verbatim: timer.cookingTimer.text)
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
        .onGeometryChange(
            for: CGRect.self,
            of: { $0.frame(in: .global) },
            action: { frame in onCancelButtonFrameChange?(frame) }
        )
    }

    /// Where the timer comes from: the step naming it, or the cook.
    private var source: Text {
        switch timer.cookingTimer {
        case .step(let stepTimer): Text("Step \(stepTimer.stepNumber)", bundle: .module)
        case .custom: Text("Custom", bundle: .module)
        }
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
