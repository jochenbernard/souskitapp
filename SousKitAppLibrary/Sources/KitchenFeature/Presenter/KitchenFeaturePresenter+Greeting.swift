import Foundation

extension KitchenFeaturePresenter {
    @MainActor
    func topScreenDidAppear() async {
        while let nextChange = greet() {
            do {
                try await greetingClock.sleep(nextChange)
            } catch {
                return
            }
        }
    }

    /// Greets the cook for the time it is now.
    ///
    /// - Returns: When the greeting changes next, or `nil` where the calendar finds no such moment.
    @MainActor
    @discardableResult
    func greet() -> Date? {
        let now = greetingClock.now()
        let greeting = KitchenGreetingSchedule.greeting(at: now, in: greetingClock.calendar)

        // Written only on a change, so the title is not drawn again while a pop slides over it.
        if viewModel.greeting != greeting {
            viewModel.greeting = greeting
        }

        return KitchenGreetingSchedule.nextChange(after: now, in: greetingClock.calendar)
    }
}
