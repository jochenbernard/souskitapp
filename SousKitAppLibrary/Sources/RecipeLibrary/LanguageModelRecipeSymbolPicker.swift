import FoundationModels
import Observation

/// Picks recipes' symbols with the on-device model of Apple Intelligence, where the device has it ready for the
/// language it runs in.
public struct LanguageModelRecipeSymbolPicker: RecipeSymbolPicker {
    private static let instructions = """
        You illustrate recipe cards in a cooking app. For the recipe you are given, choose one symbol.
        The symbol shows the main ingredient or the kind of dish: fish for fish and seafood, birthday.cake for cakes, \
        pastries and sweet baking, carrot for vegetable dishes, leaf for salads, herbs and dressings, drop for sauces \
        and soups, cup.and.saucer for drinks, pizza.slice for pizzas, tarts and savoury pies, frying.pan for pan-fried \
        dishes and pancakes. Choose a cooking appliance such as oven or stove only when nothing about the food itself \
        fits.
        """

    public let promptVersion = 1

    /// Creates a picker.
    public init() {}

    public func availabilityUpdates() -> AsyncStream<Bool> {
        let model = SystemLanguageModel.default
        let updates = Observations { model.availability == .available && model.supportsLocale() }

        return AsyncStream { continuation in
            let task = Task {
                for await isAvailable in updates {
                    continuation.yield(isAvailable)
                }

                continuation.finish()
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    /// Picks off the caller's actor, with greedy sampling so the same input always gets the same symbol.
    @concurrent
    public func symbol(for input: RecipeSymbolInput) async throws -> String {
        let session = LanguageModelSession(instructions: Self.instructions)
        let response = try await session.respond(
            to: Self.prompt(for: input),
            generating: RecipeSymbolChoice.self,
            options: GenerationOptions(samplingMode: .greedy)
        )

        return response.content.symbol
    }

    private static func prompt(for input: RecipeSymbolInput) -> String {
        var lines = ["Title: \(input.title)"]

        if !input.tags.isEmpty {
            lines.append("Tags: \(input.tags.joined(separator: ", "))")
        }

        if let course = input.course {
            lines.append("Course: \(course)")
        }

        if let cuisine = input.cuisine {
            lines.append("Cuisine: \(cuisine)")
        }

        if !input.ingredientNames.isEmpty {
            lines.append("Ingredients: \(input.ingredientNames.joined(separator: ", "))")
        }

        return lines.joined(separator: "\n")
    }
}
