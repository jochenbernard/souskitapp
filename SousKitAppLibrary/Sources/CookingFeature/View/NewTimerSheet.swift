import DesignSystem
import SwiftUI

/// The sheet that starts a timer of a length a cook types on its keypad, as on a microwave.
struct NewTimerSheet: View {
    /// The widest the length and the keypad stand, so the keys stay a hand's span across on an iPad.
    private static let maxWidth = 440.0

    /// The keypad's rows above its last, which holds the double zero, the zero and the delete key.
    private static let digitRows = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"]]

    private let presenter: CookingFeaturePresenterProtocol
    private let entry: NewTimerEntry

    // VoiceOver finds nowhere to start while the cooking screen is hidden from it, so the sheet puts it on the length.
    @AccessibilityFocusState private var isLengthFocused: Bool

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
            content: {
                keypadEntry
            },
            actions: {
                ToolbarItem(placement: .cancellationAction) {
                    cancelButton
                }

                ToolbarItem(placement: .confirmationAction) {
                    startButton
                }
            }
        )
        // Stops growing, bar included, at the first accessibility size, where the keypad still fits on an iPhone.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .onAppear {
            isLengthFocused = true
        }
        // A key reads only its own name, so VoiceOver says what the length has come to.
        .onChange(of: entry.digits) {
            AccessibilityNotification.Announcement(spokenLength).post()
        }
    }

    private var keypadEntry: some View {
        VStack(spacing: SousSpacing.large) {
            length

            keypad
        }
        .frame(maxWidth: Self.maxWidth)
        .background {
            VoiceOverHandoff()
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

    /// The length as VoiceOver reads it, such as `5 minutes, 20 seconds`.
    private var spokenLength: String {
        (entry.duration ?? .zero).formatted(
            .units(allowed: [.hours, .minutes, .seconds], width: .wide).locale(CookingTimer.displayLocale)
        )
    }

    private var length: some View {
        HStack(alignment: .firstTextBaseline, spacing: SousSpacing.medium) {
            lengthPart(0, unit: Text("h", bundle: .module))

            lengthPart(1, unit: Text("min", bundle: .module))

            lengthPart(2, unit: Text("s", bundle: .module))
        }
        .lineLimit(1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: spokenLength))
        .accessibilityFocused($isLengthFocused)
    }

    private var keypad: some View {
        Grid(horizontalSpacing: SousSpacing.medium, verticalSpacing: SousSpacing.medium) {
            ForEach(Self.digitRows, id: \.self) { row in
                GridRow {
                    ForEach(row, id: \.self) { digits in
                        digitsKey(digits)
                    }
                }
            }

            GridRow {
                digitsKey("00")
                    .accessibilityLabel(Text("Double zero", bundle: .module))

                digitsKey("0")

                deleteKey
            }
        }
    }

    private var deleteKey: some View {
        NewTimerKey(action: presenter.didTapDeleteNewTimerDigit) {
            Image(systemName: "delete.backward")
        }
        .disabled(entry.digits.isEmpty)
        .buttonRepeatBehavior(.enabled)
        .accessibilityLabel(Text("Delete", bundle: .module))
    }

    private func start() {
        Task {
            await presenter.didTapStartNewTimer()
        }
    }

    /// The hours, the minutes or the seconds, with the digits not typed yet faded.
    private func lengthPart(_ index: Int, unit: Text) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: SousSpacing.hairline) {
            HStack(spacing: 0.0) {
                ForEach(index * 2..<index * 2 + 2, id: \.self) { position in
                    lengthDigit(at: position)
                }
            }
            .font(.largeTitle)
            .monospacedDigit()

            unit
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private func digitsKey(_ digits: String) -> some View {
        NewTimerKey(
            action: { presenter.didTapNewTimerDigits(digits) },
            label: { Text(verbatim: digits) }
        )
    }

    private func lengthDigit(at position: Int) -> some View {
        let clockDigits = Array(entry.clockDigits)
        let isTyped = position >= clockDigits.count - entry.digits.count

        return Text(verbatim: String(clockDigits[position]))
            .foregroundStyle(isTyped ? .primary : .tertiary)
    }
}

#Preview("New timer sheet") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            NewTimerSheet(
                presenter: CookingFeaturePresenterStub(),
                entry: NewTimerEntry(digits: "520")
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
