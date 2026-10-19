import CoreGraphics
import Observation
import RecipeLibrary

/// The pictures the kitchen's cards show, each as it was read last.
///
/// A view reading one picture is redrawn when that picture lands, not when another does.
@MainActor
final class KitchenThumbnails {
    @Observable
    @MainActor
    final class Slot {
        var thumbnail: CGImage?
    }

    // By picture id, so a picture replaced or landing from iCloud shows what was read of it until it is read again.
    private var slots: [String: Slot] = [:]

    nonisolated init() {}

    /// The thumbnail read last for a picture, whatever its contents were then, or `nil` where none is.
    subscript(picture: RecipePicture) -> CGImage? {
        get {
            slot(for: picture).thumbnail
        }
        set {
            slot(for: picture).thumbnail = newValue
        }
    }

    // A slot read before its picture lands is the one the picture lands in.
    private func slot(for picture: RecipePicture) -> Slot {
        if let slot = slots[picture.id] {
            return slot
        }

        let slot = Slot()
        slots[picture.id] = slot

        return slot
    }
}
