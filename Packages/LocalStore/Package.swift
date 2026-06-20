// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LocalStore",
    platforms: [.macOS(.v14)],
    products: [.library(name: "LocalStore", targets: ["LocalStore"])],
    dependencies: [.package(path: "../MiseCore")],
    targets: [
        .target(
            name: "LocalStore",
            dependencies: [.product(name: "MiseCore", package: "MiseCore")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "LocalStoreTests",
            dependencies: ["LocalStore", .product(name: "MiseCore", package: "MiseCore")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
