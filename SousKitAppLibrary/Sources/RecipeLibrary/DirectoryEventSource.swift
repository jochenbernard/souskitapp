import Foundation

/// Reports the changes to a directory's entries that reach it without file coordination, which
/// is how another app on the device writes into it.
final class DirectoryEventSource {
    private let source: DispatchSourceFileSystemObject

    /// Creates a source, or nothing where the directory cannot be opened for events.
    init?(directoryURL: URL, onChange: @escaping @Sendable () -> Void) {
        let descriptor = open(directoryURL.path(percentEncoded: false), O_EVTONLY)

        guard descriptor >= 0 else {
            return nil
        }

        self.source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .delete, .rename, .revoke],
            queue: DispatchQueue(label: "app.souskit.recipe-directory-events")
        )
        self.source.setEventHandler(handler: onChange)
        self.source.setCancelHandler {
            close(descriptor)
        }
        self.source.resume()
    }

    deinit {
        source.cancel()
    }
}
