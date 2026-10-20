import Foundation
import RecipeLibrary
import Testing

extension RecipeSymbolQueueTests {
    @Test("nothing is picked while symbols cannot be, and picking starts once they can")
    func unavailable() async throws {
        let unavailablePicker = RecipeSymbolPickerStub(isAvailable: false)
        unavailablePicker.symbols = ["Crepes": "birthday.cake"]
        let queue = RecipeSymbolQueue(picker: unavailablePicker)
        var iterator = queue.listedRecipes(following: upstream).makeAsyncIterator()

        upstreamContinuation.yield(.success([crepes()]))
        let first = try #require(await iterator.next()).get()
        try await Task.sleep(for: .milliseconds(100))

        #expect(first.map(\.symbolPick) == [nil])
        #expect(unavailablePicker.inputs.isEmpty)

        unavailablePicker.setAvailable(true)
        let symbols = try await symbols(once: ["crepes.sous"], from: &iterator)

        #expect(symbols == ["crepes.sous": "birthday.cake"])
    }

    @Test("a pick that fails is not asked for again, whatever is listed next")
    func failedPick() async throws {
        let queue = makeQueue()
        var iterator = queue.listedRecipes(following: upstream).makeAsyncIterator()
        let brioche = listed("brioche.sous", "---\ntitle: Brioche\n---\nMix @{500 g} flour@.")

        upstreamContinuation.yield(.success([brioche, crepes()]))
        _ = try await symbols(once: ["crepes.sous"], from: &iterator)
        upstreamContinuation.yield(.success([brioche, crepes(), bouillabaisse()]))
        _ = try await symbols(once: ["crepes.sous", "bouillabaisse.sous"], from: &iterator)

        #expect(picker.inputs.map(\.title) == ["Brioche", "Crepes", "Bouillabaisse"])
    }

    @Test("a pick that failed is asked for again once symbols can be picked after they could not")
    func failedThenAvailable() async throws {
        let queue = makeQueue()
        var iterator = queue.listedRecipes(following: upstream).makeAsyncIterator()
        picker.symbols = [:]

        upstreamContinuation.yield(.success([crepes()]))
        _ = await iterator.next()

        while picker.inputs.isEmpty {
            await Task.yield()
        }

        // Long enough for the failure to land before picking stops being possible.
        try await Task.sleep(for: .milliseconds(100))
        picker.symbols = ["Crepes": "birthday.cake"]
        picker.setAvailable(false)
        picker.setAvailable(true)
        let symbols = try await symbols(once: ["crepes.sous"], from: &iterator)

        #expect(symbols == ["crepes.sous": "birthday.cake"])
        #expect(picker.inputs.count == 2)
    }
}
