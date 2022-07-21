# CWasm3

CWasm3 packages the [`Wasm3 library`](https://github.com/wasm3/wasm3) inside of a Swift package. The original Wasm3 header and implementation files are unchanged, but CWasm3 does add some additional conveniences to allow for receiving the return values from WebAssembly functions instead of having them printed to the console.

CWasm3's releases mirror those of Wasm3 to make it easier to integrate with other projects.

## Installation

### Swift Package Manager

To use CWasm3 with the Swift Package Manager, add a dependency to your Package.swift file:

```swift
let package = Package(
  dependencies: [
    .package(name: "CWasm3", url: "https://github.com/shareup/cwasm3.git", .upToNextMinor(from: "0.5.0"))
  ]
)
```

## Usage

**The best way to learn how to use `CWasm3` is to look at the tests in [`vendor/cwasm3/Tests/CWasm3Tests/CWasm3Tests.swift`](vendor/cwasm3/Tests/CWasm3Tests/CWasm3Tests.swift).**

That being said, this is how you can create an instance of the Wasm3 runtime and load a Wasm module into it:

```swift
let environment = m3_NewEnvironment()
defer { m3_FreeEnvironment(environment) }

let runtime = m3_NewRuntime(environment, 512, nil)
defer { m3_FreeRuntime(runtime) }

let wasmBytes = ...
var module: IM3Module?
m3_ParseModule(environment, &module, wasmBytes, UInt32(wasmBytes.count))
m3_LoadModule(runtime, module)
```

## Development

The actual Swift project lives inside of `vendor/cwasm3`. This project is compiled into an [XCFramework](https://developer.apple.com/videos/play/wwdc2019/416/), which is then exposed via the top-level CWasm3 project. The reason for this is performance and reliability. Unless CWasm3 is compiled with optimizations, running any significant WebAssembly modules via CWasm3 is painfully slow, which makes development difficult.

If the Wasm3 library is updated, follow these steps to update CWasm3.

1. Install [swift-create-xcframework](https://github.com/unsignedapps/swift-create-xcframework#installation)
2. Run `bin/update-wasm3.sh`
3. Run `bin/create-xcframework.sh`
4. Update the binary target path in `Package.swift`

## License

The license for CWasm3 is the standard MIT license. You can find it in the `LICENSE` file.

The license for Wasm3 is also the standard MIT license. You can find it [here](https://github.com/wasm3/wasm3/blob/master/LICENSE).

