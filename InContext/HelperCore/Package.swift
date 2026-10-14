// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "HelperCore",
    products: [
        .library(
            name: "HelperCore",
            targets: ["HelperCore"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/inseven/diligence.git", from: "2.0.1"),
    ],
    targets: [
        .target(
            name: "HelperCore",
            dependencies: [
                .product(name: "Diligence", package: "diligence"),
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
