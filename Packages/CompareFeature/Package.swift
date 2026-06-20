// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CompareFeature",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "CompareFeature", targets: ["CompareFeature"]),
    ],
    dependencies: [
        .package(path: "../MiseUI"),
        .package(path: "../RecommenderEngine"),
        .package(path: "../MiseCore"),
    ],
    targets: [
        .target(
            name: "CompareFeature",
            dependencies: ["MiseUI", "RecommenderEngine", "MiseCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "CompareFeatureTests",
            dependencies: ["CompareFeature", "RecommenderEngine", "MiseCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
