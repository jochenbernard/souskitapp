/// A failure to pick a symbol that asking again a while later may not meet, such as the model being too busy.
public struct RecipeSymbolPickerBusyError: Error {
    /// Creates the error.
    public init() {}
}
