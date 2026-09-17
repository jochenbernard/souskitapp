import Foundation
import SwiftUI

/// A header key the recipe screen has a label for, whatever language the recipe is written in.
///
/// A key outside this list is shown as the file writes it.
enum MetadataKey: String {
    case author = "author"
    case course = "course"
    case cuisine = "cuisine"
    case diet = "diet"
    case difficulty = "difficulty"
    case language = "language"
    case source = "source"
    case timeRequired = "time-required"
    case totalTime = "total-time"
    case version = "version"
    case yield = "yield"

    /// Reads a key as written in a header, where a space stands in for a hyphen.
    init?(key: String) {
        self.init(rawValue: key.lowercased().replacingOccurrences(of: " ", with: "-"))
    }

    var label: LocalizedStringKey {
        switch self {
        case .author: "Author"
        case .course: "Course"
        case .cuisine: "Cuisine"
        case .diet: "Diet"
        case .difficulty: "Difficulty"
        case .language: "Language"
        case .source: "Source"
        case .timeRequired: "Time required"
        case .totalTime: "Total time"
        case .version: "Version"
        case .yield: "Yield"
        }
    }
}
