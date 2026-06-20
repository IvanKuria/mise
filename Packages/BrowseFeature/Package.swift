// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BrowseFeature",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "BrowseFeature", targets: ["BrowseFeature"]),
    ],
    dependencies: [
        .package(path: "../MiseUI"),
        .package(path: "../FilmQuery"),
        .package(path: "../MiseCore"),
    ],
    targets: [
        .target(
            name: "BrowseFeature",
            dependencies: ["MiseUI", "FilmQuery", "MiseCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "BrowseFeatureTests",
            dependencies: ["BrowseFeature", "FilmQuery", "MiseCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
