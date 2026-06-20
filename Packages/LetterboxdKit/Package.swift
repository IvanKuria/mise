// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LetterboxdKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "LetterboxdKit", targets: ["LetterboxdKit"]),
        .executable(name: "mise-smoke", targets: ["mise-smoke"]),
    ],
    dependencies: [.package(path: "../MiseCore")],
    targets: [
        .target(
            name: "LetterboxdKit",
            dependencies: [.product(name: "MiseCore", package: "MiseCore")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .executableTarget(
            name: "mise-smoke",
            dependencies: ["LetterboxdKit", .product(name: "MiseCore", package: "MiseCore")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "LetterboxdKitTests",
            dependencies: ["LetterboxdKit", .product(name: "MiseCore", package: "MiseCore")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
