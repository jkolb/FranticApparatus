// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "FranticApparatus",
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
