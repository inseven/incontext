// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

// SwiftPM's `systemLibrary` `pkgConfig` support only forwards `-I`/`-L`/`-l` flags from the
// underlying `pkg-config` output; it silently drops `-D` flags as "prohibited". MagickWand's
// headers require `MAGICKCORE_QUANTUM_DEPTH`/`MAGICKCORE_HDRI_ENABLE`/`MAGICKCORE_CHANNEL_MASK_DEPTH`
// to be defined to compile at all, and their correct values vary by how ImageMagick was built
// (e.g. Homebrew's Q16HDRI vs a distribution's plain Q16), so we can't just hardcode them. Ask
// `pkg-config` directly and forward whatever it reports, rather than guessing per-platform.
func pkgConfigDefines(for library: String) -> [String] {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["pkg-config", "--cflags", library]

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = Pipe()

    guard (try? process.run()) != nil else {
        return []
    }
    process.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""
    return output
        .split(whereSeparator: { $0 == " " || $0.isNewline })
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { $0.hasPrefix("-D") }
}

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
        .package(path: "dependencies/diligence"),
        .package(path: "dependencies/hummingbird"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.4"),
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
               .target(name: "InContextMetadata", condition: .when(platforms: [.linux])),
               .product(name: "ArgumentParser", package: "swift-argument-parser"),
               .product(name: "Diligence", package: "diligence", condition: .when(platforms: [.macOS])),
               .product(name: "Hummingbird", package: "hummingbird"),
               .product(name: "HummingbirdFoundation", package: "hummingbird"),
           ]),
        .target(
            name: "InContextCore",
            dependencies: [
                "PlatformSupport",
                "Hoedown",
                .target(name: "CMagickWand", condition: .when(platforms: [.linux])),
                .target(name: "CAVFormat", condition: .when(platforms: [.linux])),
                .target(name: "CGStreamer", condition: .when(platforms: [.linux])),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "FSEventsWrapper", package: "FSEventsWrapper", condition:
                    .when(platforms: [.macOS])),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "HummingbirdFoundation", package: "hummingbird"),
                .product(name: "Licensable", package: "licensable"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "SQLite", package: "SQLite.swift"),
                .product(name: "SwiftSoup", package: "SwiftSoup"),
                .product(name: "Tilt", package: "Tilt"),
                .product(name: "Titlecaser", package: "Titlecaser"),
                .product(name: "Yams", package: "Yams"),
            ],
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
        .target(
            name: "InContextMetadata"),
        .systemLibrary(
            name: "CMagickWand",
            pkgConfig: "MagickWand",
            providers: [
                .apt(["libmagickwand-dev"]),
            ]),
        .systemLibrary(
            name: "CAVFormat",
            pkgConfig: "libavformat libavutil",
            providers: [
                .apt(["libavformat-dev", "libavutil-dev"]),
            ]),
        .systemLibrary(
            name: "CGStreamer",
            pkgConfig: "gstreamer-1.0",
            providers: [
                .apt(["libgstreamer1.0-dev", "libgstreamer-plugins-base1.0-dev"]),
            ]),
        .testTarget(
            name: "InContextTests",
            dependencies: [
                "InContextCore",
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
    .unsafeFlags(["-warnings-as-errors"]),
]

#if os(Linux)
let magickWandSwiftSettings: [SwiftSetting] = [
    .unsafeFlags(["-Xcc", "-D_GNU_SOURCE"], .when(platforms: [.linux])),
    .unsafeFlags(pkgConfigDefines(for: "MagickWand").flatMap { ["-Xcc", $0] }, .when(platforms: [.linux])),
]
#else
let magickWandSwiftSettings: [SwiftSetting] = []
#endif

for target in package.targets {
    guard target.type != .system else {
        continue
    }
    target.swiftSettings = target.swiftSettings ?? []
    target.swiftSettings?.append(contentsOf: magickWandSwiftSettings)
    target.swiftSettings?.append(contentsOf: swiftSettings)
}
