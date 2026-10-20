import Foundation
import RecipeLibrary
import SousKit
import Testing

@MainActor
@Suite("Recipe symbol queue", .timeLimit(.minutes(1)))
final class RecipeSymbolQueueTests {
    typealias Listing = Result<[ListedRecipe], Error>

    let parser = SousParser()
    let picker = RecipeSymbolPickerStub()
    let upstream: AsyncStream<Listing>
    let upstreamContinuation: AsyncStream<Listing>.Continuation

    var saved: [String: RecipeSymbolPick] = [:]

    init() {
        (self.upstream, self.upstreamContinuation) = AsyncStream.makeStream(of: Listing.self)
        picker.symbols = ["Crepes": "birthday.cake", "Bouillabaisse": "fish", "Vinaigrette": "drop"]
    }

    isolated deinit {
        upstreamContinuation.finish()
    }

    func makeQueue(busyRetryDelay: Duration = .seconds(2)) -> RecipeSymbolQueue {
        RecipeSymbolQueue(picker: picker, busyRetryDelay: busyRetryDelay) { [weak self] id, pick in
            self?.saved[id] = pick
        }
    }

    /// A recipe listed with the summary of `text`, holding `pick`.
    func listed(
        _ id: String,
        _ text: String,
        pick: RecipeSymbolPick? = nil,
        picture: RecipePicture? = nil
    ) -> ListedRecipe {
        let recipe = parser.parseRecipe(text).value

        return ListedRecipe(
            entry: RecipeEntry(
                id: id,
                name: id,
                availability: .downloaded,
                summary: RecipeSummary(recipe: recipe, parser: parser),
                picture: picture
            ),
            ingredientNames: recipe.foodIngredientNames,
            symbolPick: pick
        )
    }

    func crepes(pick: RecipeSymbolPick? = nil) -> ListedRecipe {
        listed(
            "crepes.sous",
            "---\ntitle: Crepes\ntags: [dessert, classic, french]\n---\nWhisk @{200 g} flour@ with @{4} eggs@.",
            pick: pick
        )
    }

    func bouillabaisse() -> ListedRecipe {
        listed("bouillabaisse.sous", "---\ntitle: Bouillabaisse\n---\nSoften @{2} fennel bulbs@.")
    }

    func vinaigrette() -> ListedRecipe {
        listed("vinaigrette.sous", "---\ntitle: Vinaigrette\n---\nWhisk @{1 tsp} dijon mustard@.")
    }

    /// A pick of `symbol` for a listed recipe as it is now.
    func pick(
        _ symbol: String,
        for listedRecipe: ListedRecipe,
        promptVersion: Int = 1
    ) throws -> RecipeSymbolPick {
        RecipeSymbolPick(
            symbol: symbol,
            input: try #require(RecipeSymbolInput(listedRecipe: listedRecipe)),
            promptVersion: promptVersion
        )
    }

    /// The symbols the stream lists next, by recipe id, once every recipe in `ids` has one.
    func symbols(
        once ids: Set<String>,
        from iterator: inout AsyncStream<Listing>.Iterator
    ) async throws -> [String: String] {
        while let listing = await iterator.next(isolation: #isolation) {
            let listedRecipes = try listing.get()
            let symbols = Dictionary(
                uniqueKeysWithValues: listedRecipes.compactMap { listedRecipe in
                    listedRecipe.symbolPick.map({ (listedRecipe.entry.id, $0.symbol) })
                }
            )

            if ids.isSubset(of: symbols.keys) {
                return symbols
            }
        }

        Issue.record("The stream ended before every recipe had a symbol.")
        return [:]
    }

    @Test("the recipes are listed at once, and again with each symbol as it lands")
    func picks() async throws {
        let queue = makeQueue()
        var iterator = queue.listedRecipes(following: upstream).makeAsyncIterator()
        picker.isHolding = true

        upstreamContinuation.yield(.success([crepes(), bouillabaisse()]))
        let first = try #require(await iterator.next()).get()

        #expect(first.map(\.symbolPick) == [nil, nil])

        picker.release()
        let symbols = try await symbols(once: ["crepes.sous", "bouillabaisse.sous"], from: &iterator)

        #expect(symbols == ["crepes.sous": "birthday.cake", "bouillabaisse.sous": "fish"])
        #expect(saved.mapValues(\.symbol) == symbols)
    }

    @Test("the model is given the title, tags, course, cuisine and ingredient names")
    func input() async throws {
        let queue = makeQueue()
        var iterator = queue.listedRecipes(following: upstream).makeAsyncIterator()
        let crepes = listed(
            "crepes.sous",
            """
            ---
            title: Crepes
            servings: 4
            course: dessert
            cuisine: french
            tags: [classic]
            ---
            Whisk @{200 g} flour@ with @{4} eggs@ on @foil@:non-food.
            """
        )

        upstreamContinuation.yield(.success([crepes]))
        _ = try await symbols(once: ["crepes.sous"], from: &iterator)
        let input = try #require(picker.inputs.first)

        #expect(input.title == "Crepes")
        #expect(input.tags == ["classic"])
        #expect(input.course == "dessert")
        #expect(input.cuisine == "french")
        #expect(input.ingredientNames == ["flour", "eggs"])
    }

    @Test("a recipe whose contents have not been read is not picked for")
    func unread() async throws {
        let queue = makeQueue()
        var iterator = queue.listedRecipes(following: upstream).makeAsyncIterator()
        let unread = ListedRecipe(
            entry: RecipeEntry(
                id: "brioche.sous",
                name: "brioche",
                availability: .notDownloaded
            ),
            ingredientNames: []
        )

        upstreamContinuation.yield(.success([unread, crepes()]))
        _ = try await symbols(once: ["crepes.sous"], from: &iterator)

        #expect(picker.inputs.map(\.title) == ["Crepes"])
    }

    @Test("a pick made from what the recipe says now, with this prompt, is not asked for again")
    func currentPick() async throws {
        let queue = makeQueue()
        var iterator = queue.listedRecipes(following: upstream).makeAsyncIterator()
        let picked = crepes(pick: try pick("birthday.cake", for: crepes()))

        upstreamContinuation.yield(.success([picked, bouillabaisse()]))
        let symbols = try await symbols(once: ["bouillabaisse.sous"], from: &iterator)

        #expect(symbols == ["crepes.sous": "birthday.cake", "bouillabaisse.sous": "fish"])
        #expect(picker.inputs.map(\.title) == ["Bouillabaisse"])
    }

    @Test("a pick made from tags the recipe no longer has is asked for again, keeping the old one until it lands")
    func changedInput() async throws {
        let queue = makeQueue()
        var iterator = queue.listedRecipes(following: upstream).makeAsyncIterator()
        let untagged = listed("crepes.sous", "---\ntitle: Crepes\n---\nWhisk @{200 g} flour@ with @{4} eggs@.")
        let stale = crepes(pick: try pick("frying.pan", for: untagged))
        picker.isHolding = true

        upstreamContinuation.yield(.success([stale]))
        let first = try #require(await iterator.next()).get()

        #expect(first.map(\.symbolPick?.symbol) == ["frying.pan"])

        picker.release()
        let landed = try #require(await iterator.next()).get()

        #expect(landed.map(\.symbolPick?.symbol) == ["birthday.cake"])
    }

    @Test("a pick made with another version of the prompt is asked for again")
    func changedPrompt() async throws {
        let queue = makeQueue()
        var iterator = queue.listedRecipes(following: upstream).makeAsyncIterator()
        let stale = crepes(pick: try pick("frying.pan", for: crepes(), promptVersion: 0))

        upstreamContinuation.yield(.success([stale]))
        _ = await iterator.next()

        while picker.inputs.isEmpty {
            await Task.yield()
        }

        #expect(picker.inputs.map(\.title) == ["Crepes"])
    }

    @Test("one recipe is picked at a time, those without a picture first")
    func oneAtATime() async throws {
        let queue = makeQueue()
        var iterator = queue.listedRecipes(following: upstream).makeAsyncIterator()
        let picture = RecipePicture(
            id: "crepes.jpg",
            modificationDate: nil,
            availability: .downloaded
        )
        let pictured = listed(
            "crepes.sous",
            "---\ntitle: Crepes\nimage: crepes.jpg\n---\nWhisk @{200 g} flour@.",
            picture: picture
        )
        picker.isHolding = true

        upstreamContinuation.yield(.success([pictured, bouillabaisse(), vinaigrette()]))
        _ = await iterator.next()

        while picker.inputs.isEmpty {
            await Task.yield()
        }

        try await Task.sleep(for: .milliseconds(100))

        #expect(picker.inputs.map(\.title) == ["Bouillabaisse"])

        picker.release()
        _ = try await symbols(once: ["crepes.sous", "bouillabaisse.sous", "vinaigrette.sous"], from: &iterator)

        #expect(picker.inputs.map(\.title) == ["Bouillabaisse", "Vinaigrette", "Crepes"])
    }

    @Test("a failure to list the recipes is passed on")
    func failure() async throws {
        let queue = makeQueue()
        var iterator = queue.listedRecipes(following: upstream).makeAsyncIterator()

        upstreamContinuation.yield(.failure(CocoaError(.fileReadNoPermission)))
        let listing = try #require(await iterator.next())

        #expect(throws: CocoaError.self) {
            try listing.get()
        }
    }

    @Test("the stream ends where the one it follows does")
    func ends() async {
        let queue = makeQueue()
        let stream = queue.listedRecipes(following: upstream)

        upstreamContinuation.finish()

        for await _ in stream {}
    }
}
