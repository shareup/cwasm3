// swift-tools-version:5.5
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
        .binaryTarget(
            name: "CWasm3",
            url: "https://github.com/shareup/cwasm3/releases/download/v0.5.1/CWasm3-0.5.0.zip",
            checksum: "4678d0f498c6f44ce6d603f7db613acf0508aac9c9d75a56dcab7fef283c0877"
        )
    ]
)
