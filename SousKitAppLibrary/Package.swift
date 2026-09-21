// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "SousKitAppLibrary",
    defaultLocalization: "en",
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
            dependencies: ["FileRecipeLibrary", "KitchenFeature", "MockRecipeLibrary", "OnboardingFeature"]
        ),
        .standardTarget(
            name: "CookingFeature",
            dependencies: ["DesignSystem", "RecipeLibrary"],
            resources: [.process("Resources/Localizable.xcstrings")]
        ),
        .standardTestTarget(
            name: "CookingFeatureTests",
            dependencies: ["LocalizationTestSupport", "CookingFeature"]
        ),
        .standardTarget(
            name: "DesignSystem",
            exclude: ["README.md"],
            resources: [.process("Resources/Localizable.xcstrings")]
        ),
        .standardTestTarget(
            name: "DesignSystemTests",
            dependencies: ["LocalizationTestSupport", "DesignSystem"]
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
            dependencies: ["CookingFeature", "RecipeFeature"],
            resources: [.process("Resources/Localizable.xcstrings")]
        ),
        .standardTestTarget(
            name: "KitchenFeatureTests",
            dependencies: ["LocalizationTestSupport", "KitchenFeature"]
        ),
        .standardTarget(name: "LocalizationTestSupport"),
        .standardTarget(
            name: "MockRecipeLibrary",
            dependencies: ["RecipeLibrary"],
            resources: [
                .copy("Resources/Recipes"),
                .process("Resources/Localizable.xcstrings")
            ]
        ),
        .standardTestTarget(
            name: "MockRecipeLibraryTests",
            dependencies: ["LocalizationTestSupport", "MockRecipeLibrary"]
        ),
        .standardTarget(
            name: "OnboardingFeature",
            dependencies: ["DesignSystem", "RecipeLibrary"],
            resources: [.process("Resources/Localizable.xcstrings")]
        ),
        .standardTestTarget(
            name: "OnboardingFeatureTests",
            dependencies: ["LocalizationTestSupport", "OnboardingFeature"]
        ),
        .standardTarget(
            name: "RecipeFeature",
            dependencies: ["DesignSystem", "RecipeLibrary"],
            resources: [.process("Resources/Localizable.xcstrings")]
        ),
        .standardTestTarget(
            name: "RecipeFeatureTests",
            dependencies: ["LocalizationTestSupport", "RecipeFeature"]
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
        exclude: [String] = [],
        resources: [Resource] = []
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
