// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ThemeKit",
    platforms: [.macOS(.v14)],
    products: [.library(name: "ThemeKit", targets: ["ThemeKit"])],
    targets: [
        .target(name: "ThemeKit", swiftSettings: [.swiftLanguageMode(.v6)]),
        .testTarget(name: "ThemeKitTests", dependencies: ["ThemeKit"], swiftSettings: [.swiftLanguageMode(.v6)]),
    ]
)
