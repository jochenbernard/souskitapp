import RecipeLibrary

extension RecipeEntry {
    /// A recipe on the device found by its path, named after the path's last name and held in the folders before it.
    static func stubbed(at path: String) -> Self {
        let components = path.split(separator: "/").map(String.init)

        return Self(
            id: path,
            name: components.last ?? path,
            availability: .downloaded,
            folderPath: Array(components.dropLast())
        )
    }
}
