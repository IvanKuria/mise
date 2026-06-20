// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ThemeStudioFeature",
    platforms: [.macOS(.v14)],
    products: [.library(name: "ThemeStudioFeature", targets: ["ThemeStudioFeature"])],
    dependencies: [
        .package(path: "../ThemeKit"),
        .package(path: "../MiseUI"),
        .package(path: "../MiseCore"),
    ],
    targets: [
        .target(
            name: "ThemeStudioFeature",
            dependencies: [
                .product(name: "ThemeKit", package: "ThemeKit"),
                .product(name: "MiseUI", package: "MiseUI"),
                .product(name: "MiseCore", package: "MiseCore"),
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "ThemeStudioFeatureTests",
            dependencies: ["ThemeStudioFeature"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
