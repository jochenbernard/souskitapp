import SwiftUI

/// Where something sits among the folders: their names from the outermost down, read out by VoiceOver as a list.
struct FolderPathText: View {
    private let names: [String]

    /// Creates the text.
    ///
    /// - Parameter names: The names of the folders, from the outermost down.
    init(_ names: [String]) {
        self.names = names
    }

    var body: some View {
        Self.text(names)
    }

    /// The path as text, for where only text goes, such as a navigation subtitle.
    ///
    /// - Parameter names: The names of the folders, from the outermost down.
    /// - Returns: The text.
    static func text(_ names: [String]) -> Text {
        Text(verbatim: names.joined(separator: " \u{203A} "))
            // A pause between the names, where VoiceOver would otherwise read out the separator.
            .accessibilityLabel(Text(verbatim: names.joined(separator: ", ")))
    }
}

#Preview {
    FolderPathText(["Mock recipes", "French", "Classic"])
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .padding()
}
