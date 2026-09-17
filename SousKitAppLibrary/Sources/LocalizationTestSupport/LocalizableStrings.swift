import Foundation

/// The strings a localized target ships, read back from its built resources.
public enum LocalizableStrings {
    /// What can go wrong reading them.
    public enum Failure: Error {
        /// The target ships no strings in that language.
        case missingLocalization(String)
    }

    /// The strings one language holds, keyed by the English the code is written with.
    ///
    /// - Parameters:
    ///   - localization: The language to read, such as `nl-BE`.
    ///   - bundle: The target's own bundle, which its test target reaches as `Bundle.module`
    ///     through `@testable import`.
    /// - Returns: Every key that language carries, with what it is written as.
    /// - Throws: ``Failure/missingLocalization(_:)`` where the target ships no such language.
    public static func strings(
        of localization: String,
        in bundle: Bundle
    ) throws -> [String: String] {
        guard
            let url = bundle.url(
                forResource: "Localizable",
                withExtension: "strings",
                subdirectory: nil,
                localization: localization
            )
        else {
            throw Failure.missingLocalization(localization)
        }

        return try PropertyListDecoder().decode([String: String].self, from: Data(contentsOf: url))
    }
}
