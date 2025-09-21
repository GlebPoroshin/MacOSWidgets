// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LiquidGlassModules",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "CoreStats", targets: ["CoreStats"]),
        .library(name: "DisplaysKit", targets: ["DisplaysKit"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"])
    ],
    targets: [
        .target(
            name: "CoreStats",
            dependencies: [],
            path: "Sources/CoreStats",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "CoreStatsTests",
            dependencies: ["CoreStats"],
            path: "Tests/CoreStatsTests"
        ),
        .target(
            name: "DisplaysKit",
            dependencies: [],
            path: "Sources/DisplaysKit"
        ),
        .testTarget(
            name: "DisplaysKitTests",
            dependencies: ["DisplaysKit"],
            path: "Tests/DisplaysKitTests"
        ),
        .target(
            name: "DesignSystem",
            dependencies: [],
            path: "Sources/DesignSystem"
        ),
        .testTarget(
            name: "DesignSystemTests",
            dependencies: ["DesignSystem"],
            path: "Tests/DesignSystemTests"
        )
    ]
)
