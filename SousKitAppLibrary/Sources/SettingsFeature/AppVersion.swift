import Foundation

/// Which release of the app is running, and which build of it.
public struct AppVersion: Sendable, Hashable {
    /// The release, such as `0.3`.
    let version: String

    /// The build of the release, such as `4`.
    let build: String

    /// The version a bundle declares, with whatever it leaves out empty.
    ///
    /// - Parameter bundle: The app's bundle.
    public init(bundle: Bundle) {
        self.init(
            version: bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
            build: bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
        )
    }

    init(version: String, build: String) {
        self.version = version
        self.build = build
    }
}
