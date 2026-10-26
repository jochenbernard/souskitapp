/// How many cards a screen of the kitchen holds, as measured last.
///
/// A class, so every copy of the presenter keeps the same one.
@MainActor
final class KitchenScreenCapacity {
    /// The most cards a screen holds, or 0 before one is measured.
    var cardCount = 0

    nonisolated init() {}
}
