import Foundation
@testable import KitchenFeature
import SousKit
import Testing

@Suite("Kitchen greeting")
struct KitchenGreetingTests {
    private static let calendar: Calendar = {
        var gregorian = Calendar(identifier: .gregorian)
        gregorian.timeZone = TimeZone(identifier: "Europe/Brussels") ?? .gmt

        return gregorian
    }()

    // A day in May 2026, clear of a change to or from daylight saving time.
    private static let day = Date(timeIntervalSinceReferenceDate: 800_000_000.0)

    private let parser = SousParser()

    /// A moment on the test's day, or on the day after.
    private static func date(
        hour: Int,
        minute: Int = 0,
        nextDay: Bool = false
    ) -> Date {
        let dayOfDate = nextDay ? calendar.date(byAdding: .day, value: 1, to: day) ?? day : day

        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: dayOfDate) ?? .distantPast
    }

    @Test(
        "the greeting follows the meal a cook is about to start",
        arguments: [
            (hour: 0, minute: 0, greeting: KitchenGreeting.evening),
            (hour: 4, minute: 59, greeting: .evening),
            (hour: 5, minute: 0, greeting: .morning),
            (hour: 11, minute: 59, greeting: .morning),
            (hour: 12, minute: 0, greeting: .afternoon),
            (hour: 16, minute: 59, greeting: .afternoon),
            (hour: 17, minute: 0, greeting: .evening),
            (hour: 23, minute: 59, greeting: .evening)
        ]
    )
    func greetingAtTheHour(hour: Int, minute: Int, greeting: KitchenGreeting) {
        let date = Self.date(hour: hour, minute: minute)

        #expect(KitchenGreetingSchedule.greeting(at: date, in: Self.calendar) == greeting)
    }

    @Test(
        "the greeting changes next at the start of the next meal, the morning's on the day after",
        arguments: [
            (hour: 4, minute: 30, change: KitchenGreetingTests.date(hour: 5)),
            (hour: 5, minute: 0, change: KitchenGreetingTests.date(hour: 12)),
            (hour: 12, minute: 30, change: KitchenGreetingTests.date(hour: 17)),
            (hour: 17, minute: 0, change: KitchenGreetingTests.date(hour: 5, nextDay: true)),
            (hour: 23, minute: 59, change: KitchenGreetingTests.date(hour: 5, nextDay: true))
        ]
    )
    func nextChange(hour: Int, minute: Int, change: Date) {
        let date = Self.date(hour: hour, minute: minute)

        #expect(KitchenGreetingSchedule.nextChange(after: date, in: Self.calendar) == change)
    }

    @MainActor
    @Test("the kitchen's own screen greets for the time it is, then again once the next meal starts")
    func topScreenFollowsTheClock() async {
        let clock = SteppingGreetingClock(at: Self.date(hour: 11, minute: 30), in: Self.calendar, wakes: 1)
        let viewModel = KitchenFeatureViewModel(recipeRepositoryName: "Recipes")
        viewModel.greeting = .evening
        let presenter = KitchenFeaturePresenter.stubbed(
            viewModel: viewModel,
            parser: parser,
            greetingClock: clock.clock
        )

        await presenter.topScreenDidAppear()

        #expect(viewModel.greeting == .afternoon)
        #expect(clock.sleeps == [Self.date(hour: 12), Self.date(hour: 17)])
    }

    @MainActor
    @Test("coming back to the app greets for the time it is now")
    func becomingActiveGreetsAgain() async {
        let clock = SteppingGreetingClock(at: Self.date(hour: 9), in: Self.calendar)
        let viewModel = KitchenFeatureViewModel(recipeRepositoryName: "Recipes")
        let presenter = KitchenFeaturePresenter.stubbed(
            viewModel: viewModel,
            parser: parser,
            greetingClock: clock.clock
        )

        clock.move(to: Self.date(hour: 18))
        await presenter.didBecomeActive()

        #expect(viewModel.greeting == .evening)
    }
}
