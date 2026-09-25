import Foundation

extension StepTimer {
    private static let scheme = "sous-timer"
    private static let host = "start"

    /// The link a step's prose opens to start this timer.
    var link: URL? {
        var components = URLComponents()
        components.scheme = Self.scheme
        components.host = Self.host
        components.queryItems = [
            URLQueryItem(name: "step", value: String(stepNumber)),
            URLQueryItem(name: "text", value: text),
            URLQueryItem(name: "seconds", value: String(seconds))
        ]
        return components.url
    }

    /// The timer a link from ``link`` starts, or `nil` for any other link.
    init?(link: URL) {
        guard
            let components = URLComponents(url: link, resolvingAgainstBaseURL: false),
            components.scheme == Self.scheme,
            components.host == Self.host,
            let queryItems = components.queryItems,
            let stepNumber = Self.value(of: "step", in: queryItems).flatMap(Int.init),
            let text = Self.value(of: "text", in: queryItems),
            let seconds = Self.value(of: "seconds", in: queryItems).flatMap(Double.init),
            seconds.isFinite,
            seconds > 0.0
        else {
            return nil
        }

        self.init(
            stepNumber: stepNumber,
            text: text,
            duration: .seconds(seconds)
        )
    }

    private static func value(of name: String, in queryItems: [URLQueryItem]) -> String? {
        queryItems.first(where: { $0.name == name })?.value
    }
}
