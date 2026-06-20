// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OnboardingFeature",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "OnboardingFeature", targets: ["OnboardingFeature"]),
    ],
    dependencies: [
        .package(path: "../MiseUI"),
        .package(path: "../MiseCore"),
    ],
    targets: [
        .target(
            name: "OnboardingFeature",
            dependencies: ["MiseUI", "MiseCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "OnboardingFeatureTests",
            dependencies: ["OnboardingFeature"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
