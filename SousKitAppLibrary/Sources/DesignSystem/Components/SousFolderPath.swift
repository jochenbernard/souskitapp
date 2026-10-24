import SwiftUI

/// Where something sits among the folders: their names from the outermost down, read out by VoiceOver as a list.
public struct SousFolderPath: View {
    private let names: [String]

    /// Creates the text.
    ///
    /// - Parameter names: The names of the folders, from the outermost down.
    public init(_ names: [String]) {
        self.names = names
    }

    public var body: some View {
        Text(verbatim: names.joined(separator: " \u{203A} "))
            // A pause between the names, where VoiceOver would otherwise read out the separator.
            .accessibilityLabel(Text(verbatim: names.joined(separator: ", ")))
    }
}

#Preview {
    SousFolderPath(["Mock recipes", "French", "Classic"])
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .padding()
}
