// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ic3",
    platforms: [
        .macOS(.v13),
    ],
    dependencies: [
        .package(url: "https://github.com/johnsundell/ink.git", from: "0.1.0"),
        .package(url: "https://github.com/jwells89/Titlecaser.git", from: "1.0.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.6"),  // Good for known structures
        .package(url: "https://github.com/behrang/YamlSwift.git", from: "3.4.4"),  // Good for unknown?
        .package(url: "https://github.com/stencilproject/Stencil.git", from: "0.15.1"),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.14.1"),
        .package(url: "https://github.com/apple/swift-markdown.git", from: "0.2.0"),
        .package(url: "https://github.com/objecthub/swift-markdownkit.git", from: "1.1.7"),
        .package(url: "https://github.com/johnfairh/swift-sass.git", from: "1.7.0"),
        .package(url: "https://github.com/BiosTheoretikos/Ogma.git", from: "0.1.3"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "ic3",
            dependencies: [
                .product(name: "DartSass", package: "swift-sass"),
                .product(name: "Ink", package: "ink"),
                .product(name: "Ogma", package: "Ogma"),
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "MarkdownKit", package: "swift-markdownkit"),
                .product(name: "Stencil", package: "Stencil"),
                .product(name: "SQLite", package: "SQLite.swift"),
                .product(name: "Titlecaser", package: "Titlecaser"),
                .product(name: "Yams", package: "Yams"),
                .product(name: "Yaml", package: "YamlSwift"),
            ],
            path: "Sources"),
        .testTarget(
            name: "ic3tests",
            dependencies: ["ic3"]),
    ]
)

// TODO: Consider whether any of these really make sense.
let swiftSettings: [SwiftSetting] = [
    // -enable-bare-slash-regex becomes
    .enableUpcomingFeature("BareSlashRegexLiterals"),
    // -warn-concurrency becomes
    .enableUpcomingFeature("StrictConcurrency"),
    .unsafeFlags(["-enable-actor-data-race-checks"],
        .when(configuration: .debug)),
]

for target in package.targets {
    target.swiftSettings = target.swiftSettings ?? []
    target.swiftSettings?.append(contentsOf: swiftSettings)
}
