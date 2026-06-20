// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TasteProfile",
    platforms: [.macOS(.v14)],
    products: [.library(name: "TasteProfile", targets: ["TasteProfile"])],
    dependencies: [
        .package(path: "../MiseCore"),
        .package(path: "../StatsEngine"),
    ],
    targets: [
        .target(
            name: "TasteProfile",
            dependencies: [
                .product(name: "MiseCore", package: "MiseCore"),
                .product(name: "StatsEngine", package: "StatsEngine"),
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "TasteProfileTests",
            dependencies: [
                "TasteProfile",
                .product(name: "MiseCore", package: "MiseCore"),
                .product(name: "StatsEngine", package: "StatsEngine"),
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
