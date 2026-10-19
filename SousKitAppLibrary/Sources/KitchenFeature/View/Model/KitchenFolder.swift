/// A folder of the repository as the kitchen lists it: the folders inside it with recipes somewhere below them, and
/// the recipes directly in it.
struct KitchenFolder: Identifiable, Hashable {
    /// The names of the folders leading down to this one, its own last, or none for the top of the repository.
    let path: [String]

    /// The folders inside this one with recipes somewhere below them, in the order they are shown.
    let folders: [Self]

    /// The recipes directly in this folder, as cards in the order they are shown.
    let cards: [KitchenRecipeCard]

    var id: [String] {
        path
    }

    /// The folder's own name, or an empty one for the top of the repository, which the repository names.
    var name: String {
        path.last ?? ""
    }

    /// Whether the folder lists nothing at all.
    var isEmpty: Bool {
        folders.isEmpty && cards.isEmpty
    }

    /// A folder somewhere below this one, this one included.
    ///
    /// - Parameter path: The names of the folders leading down to it from the top of the repository.
    /// - Returns: The folder, or `nil` where none is listed there.
    func folder(at path: [String]) -> Self? {
        guard path.count > self.path.count else {
            return path == self.path ? self : nil
        }

        let inner = Array(path.prefix(self.path.count + 1))

        return folders.first(where: { $0.path == inner })?.folder(at: path)
    }
}
