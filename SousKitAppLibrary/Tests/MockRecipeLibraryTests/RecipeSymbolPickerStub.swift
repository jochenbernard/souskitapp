import Foundation
import RecipeLibrary

/// A picker answering with the symbols a test gives it.
@MainActor
final class RecipeSymbolPickerStub: RecipeSymbolPicker {
    nonisolated let promptVersion = 1

    /// The symbol picked for each title; any other title fails to pick.
    var symbols: [String: String] = [:]

    nonisolated private let availability: AsyncStream<Bool>
    nonisolated private let availabilityContinuation: AsyncStream<Bool>.Continuation

    /// Creates a picker, whose ``availabilityUpdates()`` can be followed once.
    nonisolated init(isAvailable: Bool = true) {
        (self.availability, self.availabilityContinuation) = AsyncStream.makeStream(of: Bool.self)
        self.availabilityContinuation.yield(isAvailable)
    }

    nonisolated func availabilityUpdates() -> AsyncStream<Bool> {
        availability
    }

    @MainActor
    func symbol(for input: RecipeSymbolInput) throws -> String {
        guard let symbol = symbols[input.title] else {
            throw CocoaError(.featureUnsupported)
        }

        return symbol
    }
}
