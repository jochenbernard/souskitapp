import CoreGraphics
import Observation
import RecipeLibrary

/// The pictures the kitchen's cards show, each as it was read last, and which of them could not be read.
///
/// A view reading one picture is redrawn when that picture lands, not when another does.
@MainActor
final class KitchenThumbnails {
    @Observable
    @MainActor
    final class Slot {
        var thumbnail: CGImage?
        var didFail = false
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
            let slot = slot(for: picture)
            slot.thumbnail = newValue

            if newValue != nil, slot.didFail {
                slot.didFail = false
            }
        }
    }

    /// Whether the last read of a picture failed with no thumbnail of it set since, so none is on its way.
    func didFail(_ picture: RecipePicture) -> Bool {
        slot(for: picture).didFail
    }

    func readDidFail(of picture: RecipePicture) {
        slot(for: picture).didFail = true
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
