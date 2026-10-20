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

    @Test("a pick that fails while picking stops and starts being possible again is asked for again")
    func failedWhileUnavailableAndBack() async throws {
        let queue = makeQueue()
        var iterator = queue.listedRecipes(following: upstream).makeAsyncIterator()
        picker.isHolding = true

        upstreamContinuation.yield(.success([crepes()]))
        _ = await iterator.next()

        while picker.inputs.isEmpty {
            await Task.yield()
        }

        picker.setAvailable(false)
        picker.setAvailable(true)
        // Long enough for both changes to be taken in before the pick fails.
        try await Task.sleep(for: .milliseconds(100))
        picker.errors = [CocoaError(.featureUnsupported)]
        picker.release()
        let symbols = try await symbols(once: ["crepes.sous"], from: &iterator)

        #expect(symbols == ["crepes.sous": "birthday.cake"])
        #expect(picker.inputs.count == 2)
    }

    @Test("a pick that fails once picking stopped being possible is asked for again once it is")
    func failedOnceUnavailable() async throws {
        let queue = makeQueue()
        var iterator = queue.listedRecipes(following: upstream).makeAsyncIterator()
        picker.isHolding = true

        upstreamContinuation.yield(.success([crepes()]))
        _ = await iterator.next()

        while picker.inputs.isEmpty {
            await Task.yield()
        }

        picker.setAvailable(false)
        try await Task.sleep(for: .milliseconds(100))
        picker.errors = [CocoaError(.featureUnsupported)]
        picker.release()
        try await Task.sleep(for: .milliseconds(100))

        #expect(picker.inputs.count == 1)

        picker.setAvailable(true)
        let symbols = try await symbols(once: ["crepes.sous"], from: &iterator)

        #expect(symbols == ["crepes.sous": "birthday.cake"])
        #expect(picker.inputs.count == 2)
    }

    @Test("whether symbols can be picked is no longer followed once the stream ends")
    func availabilityEnds() async throws {
        let queue = makeQueue()
        let stream = queue.listedRecipes(following: upstream)

        upstreamContinuation.yield(.success([crepes()]))
        upstreamContinuation.finish()

        for await _ in stream {}

        for _ in 0..<100 where !picker.isAvailabilityFinished {
            try await Task.sleep(for: .milliseconds(10))
        }

        #expect(picker.isAvailabilityFinished)
        // The queue going would end the following too.
        withExtendedLifetime(queue) {}
    }
}
