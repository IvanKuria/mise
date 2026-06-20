// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TMDBKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "TMDBKit", targets: ["TMDBKit"]),
    ],
    targets: [
        .target(
            name: "TMDBKit",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "TMDBKitTests",
            dependencies: ["TMDBKit"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
