@testable import FileRecipeLibrary
import Foundation
import Synchronization

/// Reports a status set for a file as iCloud would, and what the file system reports of the rest.
final class FileStatusStub: Sendable {
    private let statuses = Mutex<[String: RecipeFileStatus]>([:])

    /// Sets what is reported of a file.
    ///
    /// - Parameters:
    ///   - status: The status.
    ///   - name: The file's name.
    func set(_ status: RecipeFileStatus, forFileNamed name: String) {
        statuses.withLock({ $0[name] = status })
    }

    /// What is reported of the file at a URL.
    ///
    /// - Parameter url: The file.
    /// - Returns: The status set for the file's name, or else what the file system reports.
    func status(at url: URL) -> RecipeFileStatus? {
        statuses.withLock({ $0[url.lastPathComponent] }) ?? RecipeFileStatus.read(at: url)
    }
}
