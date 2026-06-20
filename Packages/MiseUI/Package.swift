// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MiseUI",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "MiseUI", targets: ["MiseUI"]),
    ],
    dependencies: [
        .package(path: "../ThemeKit"),
        .package(path: "../MiseCore"),
    ],
    targets: [
        .target(
            name: "MiseUI",
            dependencies: ["ThemeKit", "MiseCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "MiseUITests",
            dependencies: ["MiseUI", "ThemeKit", "MiseCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
