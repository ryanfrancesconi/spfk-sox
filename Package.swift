// swift-tools-version: 6.2
// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi

import PackageDescription

let package = Package(
    name: "spfk-sox",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        .library(
            name: "SPFKSoX",
            targets: [
                "SPFKSoX",
                "SPFKSoXC",
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/ryanfrancesconi/spfk-audio-base", branch: "development"),
        .package(url: "https://github.com/ryanfrancesconi/spfk-testing", branch: "development"),
    ],
    targets: [
        .target(
            name: "SPFKSoX",
            dependencies: [
                "SPFKSoXC",
                .product(name: "SPFKAudioBase", package: "spfk-audio-base"),
            ]
        ),

        .target(
            name: "SPFKSoXC",
            dependencies: [
                .target(name: "libsndfile"),
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
            name: "libsndfile",
            path: "Frameworks/libsndfile.xcframework"
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
                "SPFKSoX",
                "SPFKSoXC",
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
