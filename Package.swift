// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "FilmForge",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "FilmForge", targets: ["FilmForge"])
    ],
    targets: [
        .executableTarget(
            name: "FilmForge",
            path: "Sources/FilmForge",
            swiftSettings: [
                .define("CI_SILENCE_GL_DEPRECATION")
            ]
        ),
        .testTarget(
            name: "FilmForgeTests",
            path: "Tests/FilmForgeTests"
        )
    ]
)
