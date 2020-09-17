# CWasm3

`CWasm3` packages the [`Wasm3 library`](https://github.com/wasm3/wasm3) inside of a Swift package. The original `Wasm3` header and implementation files are unchanged, but `CWasm3` does add some additional conveniences to allow for receiving the return values from WebAssembly functions instead of having them printed to the console.

`CWasm3`'s releases mirror those of `Wasm3` to make it easier to integrate with other projects.

## Installation

### Swift Package Manager

To use `CWasm3` with the Swift Package Manager, add a dependency to your Package.swift file:

```swift
let package = Package(
  dependencies: [
    .package(name: "CWasm3", url: "https://github.com/shareup/cwasm3.git", .upToNextMinor(from: "0.4.7"))
  ]
)
```

## Usage

**The best way to learn how to use `CWasm3` is to look at the tests in `Tests/CWasm3Tests/CWasm3Tests.swift`.**

That being said, this is how you can create an instance of the `Wasm3` runtime and load a Wasm module into it:

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

## License

The license for `CWasm3` is the standard MIT license. You can find it in the `LICENSE` file.

The license for `Wasm3` is also the standard MIT license. You can find it [here](https://github.com/wasm3/wasm3/blob/master/LICENSE).

