// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LetterboxdScrape",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "LetterboxdScrape", targets: ["LetterboxdScrape"]),
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.7.0"),
        .package(path: "../MiseCore"),
    ],
    targets: [
        .target(
            name: "LetterboxdScrape",
            dependencies: [
                "SwiftSoup",
                .product(name: "MiseCore", package: "MiseCore"),
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "LetterboxdScrapeTests",
            dependencies: ["LetterboxdScrape"],
            resources: [.copy("Fixtures")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
