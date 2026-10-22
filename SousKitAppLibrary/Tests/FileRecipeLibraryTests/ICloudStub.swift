import Foundation
import Synchronization

/// Stands in for iCloud over a directory of placeholders: a file asked for is held from coordinated reads until the
/// test lets it land in place of its placeholder.
final class ICloudStub: Sendable {
    private let gates: [String: DispatchSemaphore]
    private let landed = Mutex<Set<String>>([])
    private let requestCounts = Mutex<[String: Int]>([:])
    private let texts: [String: String]

    /// Creates a stub.
    ///
    /// - Parameter texts: What each file holds once it lands, by name.
    init(texts: [String: String]) {
        self.texts = texts
        self.gates = texts.mapValues({ _ in DispatchSemaphore(value: 0) })
    }

    /// Lets every file still held land, so no thread outlives the stub.
    deinit {
        land(Array(texts.keys))
    }

    /// How many times each file was asked for, by name.
    var requests: [String: Int] {
        requestCounts.withLock({ $0 })
    }

    /// Asks for a file, returning once a read of it waits for it to land.
    ///
    /// - Parameter url: The file asked for.
    func startDownloading(_ url: URL) {
        let name = url.lastPathComponent
        let isFirstRequest = requestCounts.withLock { requests in
            requests[name, default: 0] += 1

            return requests[name] == 1
        }

        guard isFirstRequest, let text = texts[name], let gate = gates[name] else {
            return
        }

        let placeholderURL = url.deletingLastPathComponent().appending(path: ".\(name).icloud")
        let isHeld = DispatchSemaphore(value: 0)

        Thread {
            NSFileCoordinator().coordinate(writingItemAt: url, options: .forReplacing, error: nil) { writingURL in
                isHeld.signal()
                gate.wait()
                try? Data(text.utf8).write(to: writingURL)
                try? FileManager.default.removeItem(at: placeholderURL)
            }
        }
        .start()

        isHeld.wait()
    }

    /// Lets files land, whether they were asked for yet or not.
    ///
    /// - Parameter names: The names of the files.
    func land(_ names: [String]) {
        let newNames = landed.withLock { landed in
            names.filter({ landed.insert($0).inserted })
        }

        newNames.forEach({ gates[$0]?.signal() })
    }
}
