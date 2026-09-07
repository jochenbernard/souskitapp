import SwiftUI

/// The Sous app.
public struct SousKitApp: App {
    private let appFeature = AppFeatureFactory().makeAppFeature()

    /// Creates the app.
    public init() {}

    public var body: some Scene {
        WindowGroup {
            appFeature.makeView()
        }
    }
}
