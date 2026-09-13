import SwiftUI

/// The mark beside the wordmark, the one place type is set in semibold.
public struct SousLockup: View {
    private let markSize: CGFloat
    private let wordmarkSize: CGFloat

    /// Creates a lockup.
    ///
    /// Both sizes are fixed, not scaled: the wordmark is set at the mark's size.
    ///
    /// - Parameters:
    ///   - markSize: The height the mark is drawn at.
    ///   - wordmarkSize: The point size the wordmark is set at.
    public init(markSize: CGFloat, wordmarkSize: CGFloat) {
        self.markSize = markSize
        self.wordmarkSize = wordmarkSize
    }

    public var body: some View {
        HStack(spacing: SousSpacing.xSmall) {
            SousMark(size: markSize)

            Text(verbatim: "Sous")
                .font(.system(size: wordmarkSize, weight: .semibold))
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Lockup") {
    VStack(alignment: .leading, spacing: SousSpacing.xLarge) {
        SousLockup(markSize: 44.0, wordmarkSize: 32.0)

        SousLockup(markSize: 56.0, wordmarkSize: 40.0)
    }
    .foregroundStyle(SousColor.text)
    .padding(SousSpacing.xLarge)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(SousColor.background)
}
