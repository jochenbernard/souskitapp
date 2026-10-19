import Foundation
import Synchronization

/// Records the files iCloud is asked to fetch, starting none.
final class DownloadSpy: Sendable {
    private let urls = Mutex<[URL]>([])

    /// The names of the files asked for, in order.
    var fileNames: [String] {
        urls.withLock({ $0.map(\.lastPathComponent) })
    }

    /// Records a request.
    ///
    /// - Parameter url: The file asked for.
    func startDownloading(_ url: URL) {
        urls.withLock({ $0.append(url) })
    }
}
