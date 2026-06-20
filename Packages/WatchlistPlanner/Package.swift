// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WatchlistPlanner",
    platforms: [.macOS(.v14)],
    products: [.library(name: "WatchlistPlanner", targets: ["WatchlistPlanner"])],
    dependencies: [.package(path: "../MiseCore")],
    targets: [
        .target(
            name: "WatchlistPlanner",
            dependencies: [.product(name: "MiseCore", package: "MiseCore")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "WatchlistPlannerTests",
            dependencies: ["WatchlistPlanner", .product(name: "MiseCore", package: "MiseCore")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
