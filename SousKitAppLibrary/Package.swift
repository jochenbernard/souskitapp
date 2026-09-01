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
            name: "SousKitAppLibrary",
            targets: ["SousKitAppLibrary"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/SimplyDanny/SwiftLintPlugins",
            from: "0.1.0"
        )
    ],
    targets: [
        .target(
            name: "SousKitAppLibrary",
            swiftSettings: [
                .enableUpcomingFeature("InferIsolatedConformances"),
                .enableUpcomingFeature("MemberImportVisibility"),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault")
            ],
            plugins: [
                .plugin(
                    name: "SwiftLintBuildToolPlugin",
                    package: "SwiftLintPlugins"
                )
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
