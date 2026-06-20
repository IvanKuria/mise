// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MiseCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "MiseCore", targets: ["MiseCore"]),
    ],
    targets: [
        .target(
            name: "MiseCore",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "MiseCoreTests",
            dependencies: ["MiseCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
