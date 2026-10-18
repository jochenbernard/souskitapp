/// What the new timer sheet holds: the digits a cook typed, which fill the seconds, then the minutes, then the hours
/// from the right.
struct NewTimerEntry: Equatable {
    /// The most digits an entry holds, two each for the hours, the minutes and the seconds.
    static let capacity = 6

    /// The digits typed, in the order they were typed, never starting with a zero.
    var digits = ""

    /// The hours, minutes and seconds as they read, two digits each, with a zero for every digit not typed yet.
    var clockDigits: String {
        String(repeating: "0", count: Self.capacity - digits.count) + digits
    }

    /// How long the timer runs, or `nil` where nothing is typed.
    ///
    /// Each pair of digits counts in full, so 90 typed into the seconds runs a minute and a half.
    var duration: Duration? {
        let hours = Int(clockDigits.prefix(2)) ?? 0
        let minutes = Int(clockDigits.dropFirst(2).prefix(2)) ?? 0
        let seconds = Int(clockDigits.suffix(2)) ?? 0
        let total = hours * 3_600 + minutes * 60 + seconds

        guard total > 0 else {
            return nil
        }

        return .seconds(total)
    }
}
