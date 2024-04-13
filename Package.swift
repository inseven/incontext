// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "incontext",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "InContextCore",
            targets: [
                "InContextCore"
            ]),
        .library(
            name: "InContextCommand",
            targets: [
                "InContextCommand"
            ]),
    ],
    dependencies: [
        .package(path: "Dependencies/hummingbird"),
        .package(path: "Dependencies/Tilt"),
        .package(path: "Dependencies/Tilt/LuaSwift"),
        .package(url: "https://github.com/Frizlab/FSEventsWrapper.git", from: "2.1.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", "1.0.0" ..< "3.0.0"),
        .package(path: "Dependencies/swift-log"),
        .package(url: "https://github.com/behrang/YamlSwift.git", from: "3.4.4"),  // Good for unknown?
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.6"),  // Good for known structures
        .package(url: "https://github.com/jwells89/Titlecaser.git", from: "1.0.0"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.14.1"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
       .executableTarget(
            name: "incontext",
            dependencies: [
               "InContextCore",
               "InContextCommand",
               /* "InContextMetadata", */
               .product(name: "ArgumentParser", package: "swift-argument-parser"),
               .product(name: "Hummingbird", package: "hummingbird"),
               .product(name: "HummingbirdFoundation", package: "hummingbird"),
           ],
           linkerSettings: [.unsafeFlags(["-L/libs"])]),
       .target(
            name: "InContextCommand",
            dependencies: [
               "InContextCore",
               .product(name: "ArgumentParser", package: "swift-argument-parser"),
               .product(name: "Hummingbird", package: "hummingbird"),
               .product(name: "HummingbirdFoundation", package: "hummingbird"),
           ]),
        .target(
            name: "InContextCore",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "FSEventsWrapper", package: "FSEventsWrapper", condition:
                    .when(platforms: [.macOS])),
                .target(name: "InContextCoreLinux", condition:
                    .when(platforms: [.linux])),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "HummingbirdFoundation", package: "hummingbird"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "SQLite", package: "SQLite.swift"),
                .product(name: "SwiftSoup", package: "SwiftSoup"),
                .product(name: "Tilt", package: "Tilt"),
                .product(name: "Titlecaser", package: "Titlecaser"),
                .product(name: "Yaml", package: "YamlSwift"),
                .product(name: "Yams", package: "Yams"),
                "Hoedown",
            ],
            linkerSettings: [.unsafeFlags(["-L/libs"])],
            plugins: [
                .plugin(name: "EmbedLuaPlugin", package: "LuaSwift")
            ]),
        .target(
            name: "InContextCoreLinux"),
        .testTarget(
            name: "InContextTests",
            dependencies: [
                "InContextCore"
            ],
            resources: [
                .process("Resources")
            ]),
        .target(
            name: "Hoedown",
            dependencies: [],
            path: "Dependencies/hoedown",
            sources: [
                "src"
            ],
            publicHeadersPath: "src"
        )
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
