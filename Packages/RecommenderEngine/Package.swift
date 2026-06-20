// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RecommenderEngine",
    platforms: [.macOS(.v14)],
    products: [.library(name: "RecommenderEngine", targets: ["RecommenderEngine"])],
    dependencies: [.package(path: "../MiseCore")],
    targets: [
        .target(
            name: "RecommenderEngine",
            dependencies: [.product(name: "MiseCore", package: "MiseCore")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "RecommenderEngineTests",
            dependencies: ["RecommenderEngine", .product(name: "MiseCore", package: "MiseCore")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
