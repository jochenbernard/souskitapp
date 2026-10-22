import SousKit

/// How long a recipe takes from start to finish, as its header gives it.
public enum TotalTime: Sendable, Hashable {
    /// A length of time.
    case duration(Duration)

    /// The header's own words, where they name no length of time that can be read, such as `about a day`.
    case written(String)

    private static let totalKeys = ["total-time", "time-required"]
    private static let partKeys = ["prep-time", "cook-time"]

    /// Reads the total time off a header: its `total-time`, else its `time-required`, else its `prep-time` and
    /// `cook-time` added up.
    ///
    /// A time is read the way a step's timer is. Prep and cook are only added up where every one the header gives
    /// reads as a length of time.
    ///
    /// - Parameters:
    ///   - metadata: The recipe's header.
    ///   - parser: What the times are read with.
    /// - Returns: The total time, or `nil` where the header gives neither a total nor a part that reads.
    public init?(metadata: Metadata, parser: SousParser) {
        // A key with no value gives no time, so it neither shows as a blank total nor stops the parts adding up.
        if let total = Self.totalKeys.lazy.compactMap({ metadata[$0] }).first(where: { !$0.isEmpty }) {
            self = Self.duration(of: total, parser: parser).map(Self.duration) ?? .written(total)
            return
        }

        let parts = Self.partKeys.compactMap({ metadata[$0] }).filter({ !$0.isEmpty })
        let durations = parts.compactMap({ Self.duration(of: $0, parser: parser) })

        guard
            !durations.isEmpty,
            durations.count == parts.count
        else {
            return nil
        }

        self = .duration(durations.reduce(.zero, +))
    }

    /// A header value read as the timer a step would write with it, or `nil` where it names no length of time.
    private static func duration(of value: String, parser: SousParser) -> Duration? {
        // A tilde would end the timer early, so a value holding one is left as written.
        guard !value.contains("~") else {
            return nil
        }

        return parser.parseRecipe("~\(value)~").value.timers.first.flatMap(TimerDuration.duration(of:))
    }
}
