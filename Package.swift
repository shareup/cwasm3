// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "CWasm3",
    products: [
        .library(
            name: "CWasm3",
            targets: ["CWasm3"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CWasm3"),
        .testTarget(
            name: "CWasm3Tests",
            dependencies: ["CWasm3"]),
    ]
)
