import Foundation

/// How a scale's number is written, and how one a cook types is read.
public enum ScaleNumber {
    /// The value as the screen writes it: no trailing zeros, no grouping, in the recipe's notation
    /// rather than the reader's, since it stands beside amounts the file wrote.
    ///
    /// - Parameter value: The number to write.
    /// - Returns: The text.
    public static func text(_ value: Double) -> String {
        value.formatted(numberStyle)
    }

    /// The number a field holds, or `nil` where it holds none to scale by.
    ///
    /// A comma reads as a decimal point, since a decimal keypad offers whichever the region writes.
    ///
    /// - Parameter text: What the field holds.
    /// - Returns: The number.
    public static func value(of text: String) -> Double? {
        let value = Double(
            text
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: ",", with: ".")
        )
        // Before it is checked, since a number typed too small or too large rounds to zero or infinity.
        .map(rounded)

        guard let value, value.isFinite, value > 0.0 else {
            return nil
        }

        return value
    }

    /// The number as a scale holds it.
    ///
    /// - Parameter value: The number to hold.
    /// - Returns: The number, to six decimals.
    static func rounded(_ value: Double) -> Double {
        // Steps and switched targets land on 1.9000000000000001, which is not a number anyone typed.
        (value * 1_000_000.0).rounded() / 1_000_000.0
    }

    /// To three decimals, which is as fine as a scaled amount is written.
    private static let numberStyle = FloatingPointFormatStyle<Double>()
        .precision(.fractionLength(0...3))
        .rounded(rule: .toNearestOrAwayFromZero)
        .grouping(.never)
        .locale(Locale(identifier: "en_US_POSIX"))
}
