import DesignSystem
import SwiftUI

/// The question whether to cancel a running timer, pointing at the timer's cancel button.
///
/// The screen asks it rather than the timer's row, since a switch of the layout builds the rows anew.
struct RunningTimerCancelConfirmation: View {
    private let presenter: CookingFeaturePresenterProtocol
    private let timer: RunningTimer?
    private let motion: RunningTimersMotion

    // Kept while the question closes, and until the rows of a new layout measure their buttons.
    @State private var askedTimer: RunningTimer?
    @State private var buttonFrame = CGRect.zero

    /// - Parameters:
    ///   - timer: The timer the question asks about, or `nil` while none is asked about.
    ///   - motion: Where the layout showing the timers measured their cancel buttons.
    init(
        presenter: CookingFeaturePresenterProtocol,
        timer: RunningTimer?,
        motion: RunningTimersMotion
    ) {
        self.presenter = presenter
        self.timer = timer
        self.motion = motion
    }

    var body: some View {
        GeometryReader { proxy in
            source(in: proxy.frame(in: .global))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: timer, initial: true) { _, timer in
            if let timer {
                askedTimer = timer
            }
        }
        .onChange(of: measuredButtonFrame, initial: true) { _, frame in
            if let frame {
                buttonFrame = frame
            }
        }
    }

    private func source(in region: CGRect) -> some View {
        let frame = measuredButtonFrame ?? buttonFrame

        return Color.clear
            .frame(width: frame.width, height: frame.height)
            .confirmationDialog(
                question,
                isPresented: isPresented,
                titleVisibility: .visible,
                actions: { buttons }
            )
            .position(x: frame.midX - region.minX, y: frame.midY - region.minY)
    }

    private var question: Text {
        guard let askedTimer else {
            return Text(verbatim: "")
        }

        switch askedTimer.cookingTimer {
        case .step(let stepTimer):
            return Text("Cancel the \(stepTimer.text) timer from step \(stepTimer.stepNumber)?", bundle: .module)

        case .custom:
            return Text("Cancel the custom \(askedTimer.cookingTimer.text) timer?", bundle: .module)
        }
    }

    private var isPresented: Binding<Bool> {
        Binding(
            get: { timer != nil },
            set: { presenter.didChangeIsConfirmingCancelTimer($0) }
        )
    }

    @ViewBuilder
    private var buttons: some View {
        Button(role: .destructive, action: presenter.didConfirmCancelTimer) {
            Text("Cancel timer", bundle: .module)
        }

        Button(
            role: .cancel,
            action: {},
            label: { Text("Keep timer", bundle: .module) }
        )
    }

    private var measuredButtonFrame: CGRect? {
        timer.flatMap { motion.cancelButtonFrames[$0.id] }
    }
}

#Preview("Running timer cancel confirmation") {
    let timer = RunningTimersPreview.timers()[1]
    let motion = RunningTimersMotion()
    motion.cancelButtonFrames[timer.id] = CGRect(x: 320.0, y: 400.0, width: 44.0, height: 44.0)

    return RunningTimerCancelConfirmation(
        presenter: CookingFeaturePresenterStub(),
        timer: timer,
        motion: motion
    )
    .sousPage()
}
