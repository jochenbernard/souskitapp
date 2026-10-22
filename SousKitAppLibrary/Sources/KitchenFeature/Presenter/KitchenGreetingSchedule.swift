import Foundation

/// When the kitchen's greeting changes: at the hours a cook starts on the next meal.
enum KitchenGreetingSchedule {
    // Breakfast from 05:00, lunch from 12:00, and dinner, or anything later, from 17:00.
    private static let starts: [(hour: Int, greeting: KitchenGreeting)] = [
        (hour: 5, greeting: .morning),
        (hour: 12, greeting: .afternoon),
        (hour: 17, greeting: .evening)
    ]

    /// The greeting at a moment.
    ///
    /// - Parameters:
    ///   - date: The moment.
    ///   - calendar: The calendar and time zone the cook reads the time in.
    /// - Returns: The greeting.
    static func greeting(at date: Date, in calendar: Calendar) -> KitchenGreeting {
        let hour = calendar.component(.hour, from: date)

        // Before the morning's start, the evening runs on through the night.
        return starts.last(where: { $0.hour <= hour })?.greeting ?? .evening
    }

    /// The next moment the greeting changes.
    ///
    /// - Parameters:
    ///   - date: The moment to look on from.
    ///   - calendar: The calendar and time zone the cook reads the time in.
    /// - Returns: The first start after `date`, or `nil` where the calendar finds none.
    static func nextChange(after date: Date, in calendar: Calendar) -> Date? {
        starts
            .compactMap { start in
                calendar.nextDate(
                    after: date,
                    matching: DateComponents(hour: start.hour, minute: 0, second: 0),
                    matchingPolicy: .nextTime
                )
            }
            .min()
    }
}
