// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "FranticApparatus",
    platforms: [
        .macOS(.v10_12), .iOS(.v10), .tvOS(.v10), .watchOS(.v3)
    ],
    products: [
        .library(name: "FranticApparatus", targets: ["FranticApparatus"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(name: "FranticApparatus", dependencies: []),
        .testTarget(name: "FranticApparatusTests", dependencies: ["FranticApparatus"]),
    ]
)
