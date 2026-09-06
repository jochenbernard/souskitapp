// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "SousKitAppLibrary",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "AppFeature",
            targets: ["AppFeature"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/SimplyDanny/SwiftLintPlugins",
            from: "0.1.0"
        )
    ],
    targets: [
        .standardTarget(
            name: "AppFeature",
            dependencies: ["DesignSystem"]
        ),
        .standardTarget(
            name: "DesignSystem",
            exclude: ["README.md"],
            resources: [.copy("Resources/Fonts")]
        ),
        .standardTestTarget(
            name: "DesignSystemTests",
            dependencies: ["DesignSystem"]
        )
    ],
    swiftLanguageModes: [.v6]
)

private extension Target {
    /// The upcoming features every target in this package builds with.
    static var sharedSwiftSettings: [SwiftSetting] {
        [
            .enableUpcomingFeature("InferIsolatedConformances"),
            .enableUpcomingFeature("MemberImportVisibility"),
            .enableUpcomingFeature("NonisolatedNonsendingByDefault")
        ]
    }

    /// The plugins every target in this package builds with.
    static var sharedPlugins: [PluginUsage] {
        [
            .plugin(
                name: "SwiftLintBuildToolPlugin",
                package: "SwiftLintPlugins"
            )
        ]
    }

    /// A target built with this package's shared settings and plugins.
    static func standardTarget(
        name: String,
        dependencies: [Dependency] = [],
        exclude: [String] = [],
        resources: [Resource]? = nil
    ) -> Target {
        .target(
            name: name,
            dependencies: dependencies,
            exclude: exclude,
            resources: resources,
            swiftSettings: sharedSwiftSettings,
            plugins: sharedPlugins
        )
    }

    /// A test target built with this package's shared settings and plugins.
    static func standardTestTarget(
        name: String,
        dependencies: [Dependency] = []
    ) -> Target {
        .testTarget(
            name: name,
            dependencies: dependencies,
            swiftSettings: sharedSwiftSettings,
            plugins: sharedPlugins
        )
    }
}
