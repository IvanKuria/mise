// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FilmQuery",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "FilmQuery", targets: ["FilmQuery"]),
    ],
    dependencies: [
        .package(path: "../MiseCore"),
    ],
    targets: [
        .target(
            name: "FilmQuery",
            dependencies: ["MiseCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "FilmQueryTests",
            dependencies: ["FilmQuery", "MiseCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
