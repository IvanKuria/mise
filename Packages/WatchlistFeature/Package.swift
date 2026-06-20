// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WatchlistFeature",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "WatchlistFeature", targets: ["WatchlistFeature"]),
    ],
    dependencies: [
        .package(path: "../MiseUI"),
        .package(path: "../WatchlistPlanner"),
        .package(path: "../MiseCore"),
        .package(path: "../ThemeKit"),
    ],
    targets: [
        .target(
            name: "WatchlistFeature",
            dependencies: ["MiseUI", "WatchlistPlanner", "MiseCore", "ThemeKit"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "WatchlistFeatureTests",
            dependencies: ["WatchlistFeature"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
