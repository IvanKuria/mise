// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AppCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "AppCore", targets: ["AppCore"]),
    ],
    dependencies: [
        .package(path: "../MiseCore"),
        .package(path: "../LetterboxdScrape"),
        .package(path: "../LocalStore"),
        .package(path: "../FilmEnrichment"),
        .package(path: "../TMDBKit"),
    ],
    targets: [
        .target(
            name: "AppCore",
            dependencies: [
                "MiseCore",
                "LetterboxdScrape",
                "LocalStore",
                "FilmEnrichment",
                "TMDBKit",
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "AppCoreTests",
            dependencies: [
                "AppCore",
                "MiseCore",
                "LetterboxdScrape",
                "LocalStore",
                "FilmEnrichment",
                "TMDBKit",
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
