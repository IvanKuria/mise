// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "StatsEngine",
    platforms: [.macOS(.v14)],
    products: [.library(name: "StatsEngine", targets: ["StatsEngine"])],
    dependencies: [.package(path: "../MiseCore")],
    targets: [
        .target(
            name: "StatsEngine",
            dependencies: [.product(name: "MiseCore", package: "MiseCore")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "StatsEngineTests",
            dependencies: ["StatsEngine", .product(name: "MiseCore", package: "MiseCore")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
