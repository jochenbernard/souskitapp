/// A dish of the specification's examples, as a mock picture shows it.
enum MockDish: Sendable {
    /// The color of a tablecloth a dish is shown on.
    enum Cloth: Sendable {
        case blue
        case red
        case green
    }

    case boeufBourguignon
    case bouillabaisse
    case brioche
    case crepes
    case gratinDauphinois
    case moulesMarinieres
    case vinaigrette

    /// The emoji showing the dish.
    var emoji: String {
        switch self {
        case .boeufBourguignon:
            "🍲"
        case .bouillabaisse:
            "🥘"
        case .brioche:
            "🥐"
        case .crepes:
            "🥞"
        case .gratinDauphinois:
            "🥔"
        case .moulesMarinieres:
            "🦪"
        case .vinaigrette:
            "🥗"
        }
    }

    /// The tablecloth the dish is shown on.
    var cloth: Cloth {
        switch self {
        case .bouillabaisse, .brioche:
            .blue
        case .boeufBourguignon, .crepes, .moulesMarinieres:
            .red
        case .gratinDauphinois, .vinaigrette:
            .green
        }
    }
}
