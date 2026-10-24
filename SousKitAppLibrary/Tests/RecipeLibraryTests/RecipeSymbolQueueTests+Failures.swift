import Foundation
import RecipeLibrary
import Testing

extension RecipeSymbolQueueTests {
    @Test("a pick the picker is too busy for is asked for again, each time after a longer wait")
    func busyPick() async throws {
        let queue = makeQueue(busyRetryDelay: .milliseconds(50))
        var iterator = queue.listedRecipes(following: upstream).makeAsyncIterator()
        picker.errors = Array(repeating: RecipeSymbolPickerBusyError(), count: 3)

        upstreamContinuation.yield(.success([crepes()]))
        let symbols = try await symbols(once: ["crepes.sous"], from: &iterator)
        let waits = zip(picker.askTimes, picker.askTimes.dropFirst()).map({ $1 - $0 })

        #expect(symbols == ["crepes.sous": "birthday.cake"])
        try #require(waits.count == 3)
        #expect(waits[0] >= .milliseconds(50))
        #expect(waits[1] >= .milliseconds(100))
        #expect(waits[2] >= .milliseconds(200))
    }

    @Test("a pick the picker stays too busy for is asked for a few times, then not again")
    func lastingBusyPick() async throws {
        let queue = makeQueue(busyRetryDelay: .milliseconds(1))
        var iterator = queue.listedRecipes(following: upstream).makeAsyncIterator()
        picker.errors = Array(repeating: RecipeSymbolPickerBusyError(), count: 6)

        upstreamContinuation.yield(.success([crepes(), bouillabaisse()]))
        let symbols = try await symbols(once: ["bouillabaisse.sous"], from: &iterator)
        try await Task.sleep(for: .milliseconds(100))

        #expect(symbols == ["bouillabaisse.sous": "fish"])
        #expect(picker.inputs.map(\.title) == Array(repeating: "Crepes", count: 6) + ["Bouillabaisse"])
    }

    @Test("a pick that failed is asked for again once its recipe is listed again after it went")
    func failedPickRelisted() async throws {
        let queue = makeQueue()
        var iterator = queue.listedRecipes(following: upstream).makeAsyncIterator()
        let brioche = listed("brioche.sous", "---\ntitle: Brioche\n---\nMix @{500 g} flour@.")

        upstreamContinuation.yield(.success([brioche, crepes()]))
        _ = try await symbols(once: ["crepes.sous"], from: &iterator)
        upstreamContinuation.yield(.success([crepes()]))
        _ = await iterator.next(isolation: #isolation)
        upstreamContinuation.yield(.success([brioche, crepes()]))
        _ = await iterator.next(isolation: #isolation)

        while picker.inputs.count < 3 {
            await Task.yield()
        }

        #expect(picker.inputs.map(\.title) == ["Brioche", "Crepes", "Brioche"])
    }
}
