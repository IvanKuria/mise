// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DashboardFeature",
    platforms: [.macOS(.v14)],
    products: [.library(name: "DashboardFeature", targets: ["DashboardFeature"])],
    dependencies: [
        .package(path: "../MiseUI"),
        .package(path: "../StatsEngine"),
        .package(path: "../MiseCore"),
    ],
    targets: [
        .target(
            name: "DashboardFeature",
            dependencies: [
                .product(name: "MiseUI", package: "MiseUI"),
                .product(name: "StatsEngine", package: "StatsEngine"),
                .product(name: "MiseCore", package: "MiseCore"),
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "DashboardFeatureTests",
            dependencies: ["DashboardFeature"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
