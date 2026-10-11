import DesignSystem
import SwiftUI

/// The sheet that starts a timer of a length a cook enters: one number, and what that number counts.
struct NewTimerSheet: View {
    private let presenter: CookingFeaturePresenterProtocol
    private let entry: NewTimerEntry

    init(
        presenter: CookingFeaturePresenterProtocol,
        entry: NewTimerEntry
    ) {
        self.presenter = presenter
        self.entry = entry
    }

    var body: some View {
        SousSheet(
            Text("New timer", bundle: .module),
            content: { content },
            actions: {
                ToolbarItem(placement: .cancellationAction) {
                    cancelButton
                }

                ToolbarItem(placement: .confirmationAction) {
                    startButton
                }
            }
        )
    }

    private var content: some View {
        VStack(spacing: SousSpacing.xLarge) {
            number

            units
        }
    }

    private var cancelButton: some View {
        Button(role: .cancel, action: { presenter.didChangeIsAddingTimer(false) })
    }

    private var startButton: some View {
        Button(role: .confirm, action: start)
            .disabled(entry.duration == nil)
            .accessibilityLabel(Text("Start timer", bundle: .module))
    }

    private var number: some View {
        SousNumberField(
            entry.unit.name,
            text: Binding(get: { entry.text }, set: { presenter.didChangeNewTimerText($0) }),
            prompt: Text(verbatim: "0"),
            onStep: { presenter.didStepNewTimer(by: $0) }
        )
    }

    private var units: some View {
        SousFlowLayout(spacing: SousSpacing.small) {
            ForEach(TimerUnit.allCases, id: \.self) { unit in
                unitChip(unit)
            }
        }
    }

    private func start() {
        Task {
            await presenter.didTapStartNewTimer()
        }
    }

    private func unitChip(_ unit: TimerUnit) -> some View {
        Button(
            action: { presenter.didTapNewTimerUnit(unit) },
            label: { unit.name }
        )
        .buttonStyle(.sousChip(isSelected: unit == entry.unit))
    }
}

#Preview("New timer sheet") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            NewTimerSheet(
                presenter: CookingFeaturePresenterStub(),
                entry: NewTimerEntry(text: "15", unit: .minutes)
            )
        }
}

#Preview("New timer sheet, empty") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            NewTimerSheet(
                presenter: CookingFeaturePresenterStub(),
                entry: NewTimerEntry()
            )
        }
}
