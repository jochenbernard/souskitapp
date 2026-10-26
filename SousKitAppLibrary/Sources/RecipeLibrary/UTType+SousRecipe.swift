import UniformTypeIdentifiers

extension UTType {
    /// A recipe written in Sous, as a `.sous` file holds it.
    public static let sousRecipe = UTType(exportedAs: "app.souskit.sous", conformingTo: .plainText)
}
