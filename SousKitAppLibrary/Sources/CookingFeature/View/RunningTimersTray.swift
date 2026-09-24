import DesignSystem
import SwiftUI

/// The timers running, one row each, kept in view over the steps and scrolling once they outgrow their room.
struct RunningTimersTray: View {
    /// How the tray moves as timers come and go.
    static let animation = Animation.spring(duration: 0.5, bounce: 0.45)

    private let presenter: CookingFeaturePresenterProtocol
    private let timers: [RunningTimer]
    private let timerConfirmingCancel: RunningTimer?
    private let maxHeight: CGFloat

    private let shape = RoundedRectangle(cornerRadius: SousRadius.large)

    @State private var rowsHeight = 0.0

    init(
        presenter: CookingFeaturePresenterProtocol,
        timers: [RunningTimer],
        timerConfirmingCancel: RunningTimer?,
        maxHeight: CGFloat
    ) {
        self.presenter = presenter
        self.timers = timers
        self.timerConfirmingCancel = timerConfirmingCancel
        self.maxHeight = maxHeight
    }

    var body: some View {
        ScrollView {
            rows
                .onGeometryChange(for: CGFloat.self, of: \.size.height) { height in
                    rowsHeight = height
                }
        }
        .scrollBounceBehavior(.basedOnSize)
        // Hugging the rows until they outgrow the room keeps a short tray short, while a long one scrolls.
        .frame(maxHeight: min(rowsHeight, maxHeight))
        .animation(Self.animation, value: rowsHeight)
        .clipShape(shape)
        .glassEffect(.regular, in: shape)
    }

    private var rows: some View {
        VStack(spacing: 0.0) {
            ForEach(timers) { timer in
                RunningTimerRow(
                    presenter: presenter,
                    timer: timer,
                    isConfirmingCancel: timer.id == timerConfirmingCancel?.id
                )
                // The divider travels with its row, so rows around a removed one close up as one piece.
                .overlay(alignment: .top) {
                    divider(above: timer)
                }
                // Shrinking in place leaves the rows around it to close the gap, which a slide would cross.
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
    }

    @ViewBuilder
    private func divider(above timer: RunningTimer) -> some View {
        if timer.id != timers.first?.id {
            Divider()
        }
    }
}

#Preview("Running timers tray") {
    let date = Date.now

    VStack {
        Spacer()

        RunningTimersTray(
            presenter: CookingFeaturePresenterStub(),
            timers: [
                RunningTimer(
                    id: UUID(),
                    stepTimer: StepTimer(stepNumber: 2, text: "5-6 min", duration: .seconds(300)),
                    endDate: date,
                    isRinging: true
                ),
                RunningTimer(
                    id: UUID(),
                    stepTimer: StepTimer(stepNumber: 3, text: "15 min", duration: .seconds(900)),
                    endDate: date.addingTimeInterval(260),
                    isRinging: false
                )
            ],
            timerConfirmingCancel: nil,
            maxHeight: .infinity
        )
    }
    .sousPagePadding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .sousPage()
}
