import SwiftUI

/// What a screen could not do, with the reason under it, in a callout.
///
/// The title is taken as a `Text` so it reads from the screen's own bundle.
public struct SousFailureNote: View {
    private let title: Text
    private let message: String

    /// Creates a note.
    ///
    /// - Parameters:
    ///   - title: What failed, in the screen's own words.
    ///   - message: The reason to show under the title.
    public init(_ title: Text, message: String) {
        self.title = title
        self.message = message
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: SousSpacing.small) {
            title

            Text(verbatim: message)
        }
        .sousCallout()
    }
}

#Preview("Failure note") {
    VStack(alignment: .leading, spacing: SousSpacing.medium) {
        SousFailureNote(
            Text("This folder could not be read"),
            message: "The folder no longer exists."
        )

        SousFailureNote(
            Text("This recipe could not be read"),
            message: "The recipe no longer exists."
        )
    }
    .padding(SousSpacing.xLarge)
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .topLeading
    )
    .background(.groupedBackground)
}
