import SousKit

/// How long a recipe takes from start to finish, as its header gives it.
public enum TotalTime: Sendable, Hashable {
    /// A length of time.
    case duration(Duration)

    /// The header's own words, where they name no length of time that can be read, such as `about a day`.
    case written(String)

    private static let totalKey = "total-time"
    private static let partKeys = ["prep-time", "cook-time"]

    /// Reads the total time off a header: its `total-time`, or its `prep-time` and `cook-time` added up.
    ///
    /// A time is read the way a step's timer is. Prep and cook are only added up where every one the header gives
    /// reads as a length of time.
    ///
    /// - Parameters:
    ///   - metadata: The recipe's header.
    ///   - parser: What the times are read with.
    /// - Returns: The total time, or `nil` where the header gives neither a total nor a part that reads.
    public init?(metadata: Metadata, parser: SousParser) {
        if let total = metadata[Self.totalKey] {
            self = Self.duration(of: total, parser: parser).map(Self.duration) ?? .written(total)
            return
        }

        let parts = Self.partKeys.compactMap({ metadata[$0] })
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
