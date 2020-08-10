# CWasm3

`CWasm3` packages the [`wasm3 library`](https://github.com/wasm3/wasm3) inside of a Swift package. The original `wasm3` header and implementation files are unchanged, but `CWasm3` does add some additional conveniences to allow for receiving the return values from WebAssembly functions instead of having them printed to the console.

`CWasm3`'s releases mirror those of `wasm3` to make it easier to integrate with other projects.

## Installation

### Swift Package Manager

To use `CWasm3` with the Swift Package Manager, add a dependency to your Package.swift file:

```swift
let package = Package(
  dependencies: [
    .package(url: "https://github.com/shareup/cwasm3.git", .upToNextMinor(from: "0.4.7"))
  ]
)
```

## License

The license for `CWasm3` is the standard MIT license. You can find it in the `LICENSE` file.

The license for `wasm3` is also the standard MIT license. You can find it [here](https://github.com/wasm3/wasm3/blob/master/LICENSE).

