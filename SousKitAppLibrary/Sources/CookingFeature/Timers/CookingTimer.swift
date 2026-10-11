import Foundation

/// A timer a cook starts: one a step names, or one of a length the cook entered.
public enum CookingTimer: Hashable, Codable, Sendable {
    /// A timer a step names.
    case step(StepTimer)

    /// A timer of a length a cook entered, which no step names.
    case custom(Duration)

    /// The language the screen is written in, which is the one it reads a length of time in.
    private static let displayLocale = Locale(
        identifier: Bundle.module.preferredLocalizations.first ?? "en"
    )

    /// How long the timer runs as a cook reads it: as the step writes it, or such as `1 hr, 30 min` for one the cook
    /// entered.
    var text: String {
        switch self {
        case .step(let stepTimer):
            stepTimer.text

        case .custom(let duration):
            duration.formatted(
                .units(allowed: [.hours, .minutes, .seconds], width: .abbreviated).locale(Self.displayLocale)
            )
        }
    }

    /// How long the timer runs, in seconds.
    var seconds: Double {
        switch self {
        case .step(let stepTimer): stepTimer.seconds
        case .custom(let duration): duration / .seconds(1)
        }
    }
}
