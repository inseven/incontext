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
        .package(url: "https://github.com/inseven/glitter.git", from: "0.1.3"),
        .package(url: "https://github.com/inseven/interact.git", from: "3.10.7"),
    ],
    targets: [
        .target(
            name: "HelperCore",
            dependencies: [
                .product(name: "Glitter", package: "glitter"),
                .product(name: "Interact", package: "interact"),
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
