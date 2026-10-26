import QuickLookThumbnailing
import UIKit

/// Draws what the Files app shows for a Sous recipe: the Sous mark on a page.
final class ThumbnailProvider: QLThumbnailProvider {
    override func provideThumbnail(
        for request: QLFileThumbnailRequest,
        // The override keeps the escaping handler its superclass declares.
        // swiftlint:disable:next unneeded_escaping
        _ handler: @escaping (QLThumbnailReply?, Error?) -> Void
    ) {
        let size = DocumentIcon.size(fitting: request.maximumSize)
        let reply = QLThumbnailReply(contextSize: size) {
            DocumentIcon.draw(in: CGRect(origin: .zero, size: size))
            return true
        }

        handler(reply, nil)
    }
}
