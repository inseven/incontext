// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "HelperCore",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "HelperCore",
            targets: ["HelperCore"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/inseven/glitter.git", .upToNextMajor(from: "0.1.3")),
    ],
    targets: [
        .target(
            name: "HelperCore",
            dependencies: [
                .product(name: "Glitter", package: "glitter", condition: .when(platforms: [.macOS])),
            ],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
        .testTarget(
            name: "HelperCoreTests",
            dependencies: ["HelperCore"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
    ]
)
