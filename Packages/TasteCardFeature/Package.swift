// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TasteCardFeature",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "TasteCardFeature", targets: ["TasteCardFeature"]),
    ],
    dependencies: [
        .package(path: "../MiseUI"),
        .package(path: "../TasteProfile"),
        .package(path: "../MiseCore"),
        .package(path: "../ThemeKit"),
    ],
    targets: [
        .target(
            name: "TasteCardFeature",
            dependencies: [
                .product(name: "MiseUI", package: "MiseUI"),
                .product(name: "TasteProfile", package: "TasteProfile"),
                .product(name: "MiseCore", package: "MiseCore"),
                .product(name: "ThemeKit", package: "ThemeKit"),
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "TasteCardFeatureTests",
            dependencies: [
                "TasteCardFeature",
                .product(name: "TasteProfile", package: "TasteProfile"),
                .product(name: "MiseCore", package: "MiseCore"),
                .product(name: "ThemeKit", package: "ThemeKit"),
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
