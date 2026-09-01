// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "SousKitAppLibrary",
    platforms: [.iOS(.v26)],
    products: [
        .library(
            name: "SousKitAppLibrary",
            targets: ["SousKitAppLibrary"]
        )
    ],
    targets: [
        .target(
            name: "SousKitAppLibrary",
            swiftSettings: [
                .enableUpcomingFeature("InferIsolatedConformances"),
                .enableUpcomingFeature("MemberImportVisibility"),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
