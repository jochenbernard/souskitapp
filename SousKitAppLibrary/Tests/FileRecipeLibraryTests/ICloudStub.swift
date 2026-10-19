import Foundation
import Synchronization

/// Stands in for iCloud over a directory of placeholders: a file asked for is held from coordinated reads until its
/// turn comes, one file every `interval`, and then lands in place of its placeholder.
final class ICloudStub: Sendable {
    private struct State {
        var requests: [String: Int] = [:]
        var lastLanding = Date.distantPast
    }

    private let interval: TimeInterval
    private let state = Mutex(State())
    private let texts: [String: String]

    /// Creates a stub.
    ///
    /// - Parameters:
    ///   - texts: What each file holds once it lands, by name.
    ///   - interval: How long each file takes to land after the one before it.
    init(texts: [String: String], interval: TimeInterval) {
        self.texts = texts
        self.interval = interval
    }

    /// How many times each file was asked for, by name.
    var requests: [String: Int] {
        state.withLock({ $0.requests })
    }

    /// Asks for a file, returning once a read of it waits for it to land.
    ///
    /// - Parameter url: The file asked for.
    func startDownloading(_ url: URL) {
        let name = url.lastPathComponent
        let landing: Date? = state.withLock { state in
            state.requests[name, default: 0] += 1

            guard state.requests[name] == 1 else {
                return nil
            }

            state.lastLanding = max(state.lastLanding, Date()).addingTimeInterval(interval)

            return state.lastLanding
        }

        guard let landing, let text = texts[name] else {
            return
        }

        let placeholderURL = url.deletingLastPathComponent().appending(path: ".\(name).icloud")
        let isHeld = DispatchSemaphore(value: 0)

        Thread {
            NSFileCoordinator().coordinate(writingItemAt: url, options: .forReplacing, error: nil) { writingURL in
                isHeld.signal()
                Thread.sleep(until: landing)
                try? Data(text.utf8).write(to: writingURL)
                try? FileManager.default.removeItem(at: placeholderURL)
            }
        }
        .start()

        isHeld.wait()
    }
}
