import Foundation
import RecipeLibrary

/// A picker that can never pick, so the app's tests never wait on a symbol.
struct RecipeSymbolPickerStub: RecipeSymbolPicker {
    let promptVersion = 1

    func availabilityUpdates() -> AsyncStream<Bool> {
        let (stream, continuation) = AsyncStream.makeStream(of: Bool.self)
        continuation.yield(false)

        return stream
    }

    func symbol(for _: RecipeSymbolInput) throws -> String {
        throw CocoaError(.featureUnsupported)
    }
}
