import Foundation
import SousKit

extension RecipeSummary {
    private static let imageKey = "image"
    private static let parentDirectoryName = ".."
    private static let currentDirectoryName = "."

    /// Where the picture the header names sits in the repository, read as a path relative to the recipe's folder.
    ///
    /// Only a path leading to somewhere inside the repository counts: a web address, an absolute path, or a path
    /// climbing above the repository's top names no picture.
    ///
    /// - Parameter folderPath: The names of the folders holding the recipe, from the outermost down.
    /// - Returns: The names leading down to the picture, joined by `/`, or `nil` where the header names none.
    public func imagePath(inFolder folderPath: [String]) -> String? {
        guard
            let value = metadata[Self.imageKey]?.trimmingCharacters(in: .whitespaces),
            !value.isEmpty,
            !value.hasPrefix("/"),
            !Self.hasScheme(value)
        else {
            return nil
        }

        var components = folderPath

        for component in value.split(separator: "/").map(String.init) {
            switch component {
            case Self.currentDirectoryName:
                continue

            case Self.parentDirectoryName:
                guard components.popLast() != nil else {
                    return nil
                }

            default:
                components.append(component)
            }
        }

        return components.isEmpty ? nil : components.joined(separator: "/")
    }

    /// Whether a value opens with a URL scheme, such as `https:` or `file:`.
    private static func hasScheme(_ value: String) -> Bool {
        guard let colon = value.firstIndex(of: ":"), let first = value.first, first.isLetter else {
            return false
        }

        return value[..<colon].allSatisfy({ $0.isLetter || $0.isNumber || "+-.".contains($0) })
    }
}
