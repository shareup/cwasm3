// swift-tools-version:5.6
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
        .binaryTarget(name: "CWasm3", path: "./framework/CWasm3-0.5.0.zip")
    ]
)
