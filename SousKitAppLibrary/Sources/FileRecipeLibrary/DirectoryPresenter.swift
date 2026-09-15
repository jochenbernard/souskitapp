import Foundation

/// Reports the changes reaching a directory through file coordination, which is how iCloud
/// writes into it.
final class DirectoryPresenter: NSObject, NSFilePresenter, Sendable {
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

    /// Unregisters, which releases the presenter: `NSFileCoordinator` retains it until then.
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
