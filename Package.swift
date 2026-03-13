// swift-tools-version: 6.2
// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi

import PackageDescription

let package = Package(
    name: "spfk-sox",
    defaultLocalization: "en",
    platforms: [.macOS(.v13),],
    products: [
        .library(
            name: "SPFKSoX",
            targets: ["SPFKSoX", "SPFKSoXC",]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/ryanfrancesconi/spfk-audio-base", from: "0.0.6"),
        .package(url: "https://github.com/ryanfrancesconi/spfk-testing", from: "0.0.9"),
        .package(url: "https://github.com/sbooth/sndfile-binary-xcframework", from: "0.1.2"),
        .package(url: "https://github.com/sbooth/ogg-binary-xcframework", from: "0.1.3"),
        .package(url: "https://github.com/sbooth/flac-binary-xcframework", from: "0.2.0"),
        .package(url: "https://github.com/sbooth/vorbis-binary-xcframework", from: "0.1.2"),
        .package(url: "https://github.com/sbooth/opus-binary-xcframework", from: "0.2.2"),
    ],
    targets: [
        .target(
            name: "SPFKSoX",
            dependencies: [
                .targetItem(name: "SPFKSoXC", condition: nil),
                .product(name: "SPFKAudioBase", package: "spfk-audio-base"),
            ]
        ),

        .target(
            name: "SPFKSoXC",
            dependencies: [
                .product(name: "sndfile", package: "sndfile-binary-xcframework"),
                .product(name: "ogg", package: "ogg-binary-xcframework"),
                .product(name: "FLAC", package: "flac-binary-xcframework"),
                .product(name: "vorbis", package: "vorbis-binary-xcframework"),
                .product(name: "opus", package: "opus-binary-xcframework"),
                .target(name: "libsamplerate"),
                .target(name: "libsox"),
                .target(name: "libmad"),
                .target(name: "libmp3lame"),
                .target(name: "libmpg123"),
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include_private")
            ],
            cxxSettings: [
                .headerSearchPath("include_private")
            ]
        ),
        .binaryTarget(
            name: "libsamplerate",
            path: "Frameworks/libsamplerate.xcframework"
        ),
        .binaryTarget(
            name: "libsox",
            path: "Frameworks/libsox.xcframework"
        ),
        .binaryTarget(
            name: "libmad",
            path: "Frameworks/libmad.xcframework"
        ),
        .binaryTarget(
            name: "libmp3lame",
            path: "Frameworks/libmp3lame.xcframework"
        ),
        .binaryTarget(
            name: "libmpg123",
            path: "Frameworks/libmpg123.xcframework"
        ),
        .testTarget(
            name: "SPFKSoXTests",
            dependencies: [
                .targetItem(name: "SPFKSoX", condition: nil),
                .targetItem(name: "SPFKSoXC", condition: nil),
                .product(name: "SPFKTesting", package: "spfk-testing"),

            ],
            swiftSettings: [
                .swiftLanguageMode(.v5),
                .unsafeFlags(["-strict-concurrency=complete"]),
            ],
        ),
    ],
    cxxLanguageStandard: .cxx20
)
