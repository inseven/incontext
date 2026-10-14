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
    ],
    targets: [
        .target(
            name: "HelperCore",
            dependencies: [
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
