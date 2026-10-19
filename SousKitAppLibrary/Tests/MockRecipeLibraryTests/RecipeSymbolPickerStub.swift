import Foundation
import RecipeLibrary

/// A picker answering with the symbols a test gives it, recording what it is asked, and able to pick as a test says.
@MainActor
final class RecipeSymbolPickerStub: RecipeSymbolPicker {
    nonisolated let promptVersion: Int

    /// The symbol picked for each title; any other title fails to pick.
    var symbols: [String: String] = [:]

    /// Whether a pick waits for ``release()`` before it answers.
    var isHolding = false

    /// What the picker was asked for, oldest first.
    private(set) var inputs: [RecipeSymbolInput] = []

    nonisolated private let availability: AsyncStream<Bool>
    nonisolated private let availabilityContinuation: AsyncStream<Bool>.Continuation

    private var heldPicks: [CheckedContinuation<Void, Never>] = []

    /// Creates a picker, whose ``availabilityUpdates()`` can be followed once.
    nonisolated init(promptVersion: Int = 1, isAvailable: Bool = true) {
        self.promptVersion = promptVersion
        (self.availability, self.availabilityContinuation) = AsyncStream.makeStream(of: Bool.self)
        self.availabilityContinuation.yield(isAvailable)
    }

    nonisolated func availabilityUpdates() -> AsyncStream<Bool> {
        availability
    }

    @MainActor
    func symbol(for input: RecipeSymbolInput) async throws -> String {
        inputs.append(input)

        if isHolding {
            await withCheckedContinuation({ heldPicks.append($0) })
        }

        guard let symbol = symbols[input.title] else {
            throw CocoaError(.featureUnsupported)
        }

        return symbol
    }

    /// Answers the picks waiting, and every pick from now on at once.
    func release() {
        isHolding = false
        heldPicks.forEach({ $0.resume() })
        heldPicks = []
    }

    /// Tells the queue whether symbols can be picked now.
    func setAvailable(_ isAvailable: Bool) {
        availabilityContinuation.yield(isAvailable)
    }
}
