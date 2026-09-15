// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "SousKitAppLibrary",
    platforms: [.iOS(.v27)],
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
        ),
        .package(
            url: "https://github.com/jochenbernard/souskit",
            branch: "jochenbernard/treat-step-wraps-as-layout"
        )
    ],
    targets: [
        .standardTarget(
            name: "AppFeature",
            dependencies: ["FileRecipeLibrary", "KitchenFeature", "OnboardingFeature"]
        ),
        .standardTarget(
            name: "CookingFeature",
            dependencies: ["DesignSystem", "RecipeLibrary"]
        ),
        .standardTestTarget(
            name: "CookingFeatureTests",
            dependencies: ["CookingFeature"]
        ),
        .standardTarget(
            name: "DesignSystem",
            exclude: ["README.md"]
        ),
        .standardTestTarget(
            name: "DesignSystemTests",
            dependencies: ["DesignSystem"]
        ),
        .standardTarget(
            name: "FileRecipeLibrary",
            dependencies: ["RecipeLibrary"]
        ),
        .standardTestTarget(
            name: "FileRecipeLibraryTests",
            dependencies: ["FileRecipeLibrary"]
        ),
        .standardTarget(
            name: "KitchenFeature",
            dependencies: ["CookingFeature", "RecipeFeature"]
        ),
        .standardTestTarget(
            name: "KitchenFeatureTests",
            dependencies: ["KitchenFeature"]
        ),
        .standardTarget(
            name: "OnboardingFeature",
            dependencies: ["DesignSystem", "RecipeLibrary"]
        ),
        .standardTarget(
            name: "RecipeFeature",
            dependencies: ["DesignSystem", "RecipeLibrary"]
        ),
        .standardTestTarget(
            name: "RecipeFeatureTests",
            dependencies: ["RecipeFeature"]
        ),
        .standardTarget(
            name: "RecipeLibrary",
            dependencies: [.product(name: "SousKit", package: "souskit")]
        ),
        .standardTestTarget(
            name: "RecipeLibraryTests",
            dependencies: ["RecipeLibrary"]
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
        exclude: [String] = []
    ) -> Target {
        .target(
            name: name,
            dependencies: dependencies,
            exclude: exclude,
            swiftSettings: sharedSwiftSettings,
            plugins: sharedPlugins
        )
    }

    /// A test target built with this package's shared settings and plugins.
    static func standardTestTarget(
        name: String,
        dependencies: [Dependency]
    ) -> Target {
        .testTarget(
            name: name,
            dependencies: dependencies,
            swiftSettings: sharedSwiftSettings,
            plugins: sharedPlugins
        )
    }
}
