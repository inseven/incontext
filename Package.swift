// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

#if os(macOS)

let coreDependencies: [Target.Dependency] = [
    "PlatformSupport",
    "Hoedown",
    .product(name: "Crypto", package: "swift-crypto"),
    .product(name: "FSEventsWrapper", package: "FSEventsWrapper"),
    .product(name: "Hummingbird", package: "hummingbird"),
    .product(name: "HummingbirdFoundation", package: "hummingbird"),
    .product(name: "Licensable", package: "licensable"),
    .product(name: "Logging", package: "swift-log"),
    .product(name: "SQLite", package: "SQLite.swift"),
    .product(name: "SwiftSoup", package: "SwiftSoup"),
    .product(name: "Tilt", package: "Tilt"),
    .product(name: "Titlecaser", package: "Titlecaser"),
    .product(name: "Yams", package: "Yams"),
]

#else

let coreDependencies: [Target.Dependency] = [
    "PlatformSupport",
    "Hoedown",
    .product(name: "Crypto", package: "swift-crypto"),
    .product(name: "Hummingbird", package: "hummingbird"),
    .product(name: "HummingbirdFoundation", package: "hummingbird"),
    .product(name: "Licensable", package: "licensable"),
    .product(name: "Logging", package: "swift-log"),
    .product(name: "SQLite", package: "SQLite.swift"),
    .product(name: "SwiftExif", package: "SwiftExif"),
    .product(name: "SwiftSoup", package: "SwiftSoup"),
    .product(name: "Tilt", package: "Tilt"),
    .product(name: "Titlecaser", package: "Titlecaser"),
    .product(name: "Yams", package: "Yams"),
]

#endif

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
        .package(path: "dependencies/hummingbird"),
        .package(path: "dependencies/swift-log"),
        .package(path: "dependencies/Tilt"),
        .package(path: "dependencies/Tilt/LuaSwift"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", "1.0.0" ..< "3.0.0"),
        .package(url: "https://github.com/Frizlab/FSEventsWrapper.git", from: "2.1.0"),
        .package(url: "https://github.com/inseven/licensable", from: "0.0.13"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.6"),
        .package(url: "https://github.com/jwells89/Titlecaser.git", from: "1.0.0"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.14.1"),
        .package(url: "https://github.com/kradalby/SwiftExif.git", from: "0.0.7"),
    ],
    targets: [
       .executableTarget(
            name: "incontext",
            dependencies: [
               "InContextCore",
               "InContextCommand",
           ]),
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
            dependencies: coreDependencies,
            resources: [
                .process("Licenses"),
            ],
            plugins: [
                .plugin(name: "EmbedLuaPlugin", package: "LuaSwift")
            ]),
        .target(
            name: "PlatformSupport",
            dependencies: [
                .target(name: "PlatformSupportMacOS", condition: .when(platforms: [.macOS])),
                .target(name: "PlatformSupportLinux", condition: .when(platforms: [.linux])),
            ]),
        .target(
            name: "PlatformSupportMacOS"),
        .target(
            name: "PlatformSupportLinux"),
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
            path: "dependencies/hoedown",
            sources: [
                "src"
            ],
            publicHeadersPath: "src"
        )
    ]
)

// Enable regex literals.

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("BareSlashRegexLiterals"),
]

for target in package.targets {
    target.swiftSettings = target.swiftSettings ?? []
    target.swiftSettings?.append(contentsOf: swiftSettings)
}
