import Foundation

/// Reports the changes reaching a directory through file coordination, which is how iCloud
/// writes into it.
final class DirectoryPresenter: NSObject, NSFilePresenter {
    let presentedItemURL: URL?
    let presentedItemOperationQueue: OperationQueue

    private let onChange: @Sendable () -> Void

    init(directoryURL: URL, onChange: @escaping @Sendable () -> Void) {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .utility
        self.presentedItemURL = directoryURL
        self.presentedItemOperationQueue = queue
        self.onChange = onChange
        super.init()
        NSFileCoordinator.addFilePresenter(self)
    }

    deinit {
        NSFileCoordinator.removeFilePresenter(self)
    }

    /// Unregisters, for a caller that cannot wait for this to be deallocated.
    func stopPresenting() {
        NSFileCoordinator.removeFilePresenter(self)
    }

    func presentedItemDidChange() {
        onChange()
    }

    func presentedSubitemDidChange(at _: URL) {
        onChange()
    }

    func presentedSubitemDidAppear(at _: URL) {
        onChange()
    }

    func presentedSubitem(at _: URL, didMoveTo _: URL) {
        onChange()
    }
}
