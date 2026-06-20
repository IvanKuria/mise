// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FilmEnrichment",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "FilmEnrichment", targets: ["FilmEnrichment"]),
    ],
    dependencies: [
        .package(path: "../MiseCore"),
        .package(path: "../TMDBKit"),
    ],
    targets: [
        .target(
            name: "FilmEnrichment",
            dependencies: ["MiseCore", "TMDBKit"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "FilmEnrichmentTests",
            dependencies: ["FilmEnrichment", "MiseCore", "TMDBKit"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
