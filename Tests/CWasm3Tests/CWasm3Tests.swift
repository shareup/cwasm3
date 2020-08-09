import XCTest
@testable import CWasm3

final class CWasm3Tests: XCTestCase {
    func testCanCreateEnvironmentAndRuntime() throws {
        let environment = m3_NewEnvironment()
        defer { m3_FreeEnvironment(environment) }
        XCTAssertNotNil(environment)

        let runtime = m3_NewRuntime(environment, 512, nil)
        defer { m3_FreeRuntime(runtime) }
        XCTAssertNotNil(runtime)
    }

    func testCanCallAndReceiveReturnValueFromAdd() throws {
        let environment = m3_NewEnvironment()
        defer { m3_FreeEnvironment(environment) }

        let runtime = m3_NewRuntime(environment, 512, nil)
        defer { m3_FreeRuntime(runtime) }

        var addBytes = try addWasm()
        defer { addBytes.removeAll() }

        var module: IM3Module?
        XCTAssertNil(m3_ParseModule(environment, &module, addBytes, UInt32(addBytes.count)))
        XCTAssertNil(m3_LoadModule(runtime, module))

        var addFunction: IM3Function?
        XCTAssertNil(m3_FindFunction(&addFunction, runtime, "add"))

        let result = ["3", "12345"].withCStrings { (arguments) -> Int32 in
            var mutableArguments = arguments
            let size = UnsafeMutablePointer<Int>.allocate(capacity: 1)
            let output = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
            XCTAssertNil(wasm3_CallWithArgs(addFunction, UInt32(2), &mutableArguments, size, output))
            XCTAssertEqual(MemoryLayout<Int32>.size, size.pointee)
            return output.pointee
        }

        XCTAssertEqual(12348, result)
    }

    func testCanCallAndReceiveReturnValueFromFibonacci() throws {
        let environment = m3_NewEnvironment()
        defer { m3_FreeEnvironment(environment) }

        let runtime = m3_NewRuntime(environment, 1 * 1024 * 1024, nil)
        defer { m3_FreeRuntime(runtime) }

        var fibonacciBytes = try fibonacciWasm()
        defer { fibonacciBytes.removeAll() }

        var module: IM3Module?
        XCTAssertNil(m3_ParseModule(environment, &module, fibonacciBytes, UInt32(fibonacciBytes.count)))
        XCTAssertNil(m3_LoadModule(runtime, module))

        var fibonacciFunction: IM3Function?
        XCTAssertNil(m3_FindFunction(&fibonacciFunction, runtime, "fib"))

        let result = ["25"].withCStrings { (arguments) -> Int64 in
            var mutableArguments = arguments
            let size = UnsafeMutablePointer<Int>.allocate(capacity: 1)
            let output = UnsafeMutablePointer<Int64>.allocate(capacity: 1)
            XCTAssertNil(wasm3_CallWithArgs(fibonacciFunction, UInt32(1), &mutableArguments, size, output))
            XCTAssertEqual(MemoryLayout<Int64>.size, size.pointee)
            return output.pointee
        }

        XCTAssertEqual(75025, result)
    }

    func testImportingNativeFunction() throws {
        let environment = m3_NewEnvironment()
        defer { m3_FreeEnvironment(environment) }

        let runtime = m3_NewRuntime(environment, 512, nil)
        defer { m3_FreeRuntime(runtime) }

        var importedAddBytes = try importedAddFunc()
        defer { importedAddBytes.removeAll() }

        var module: IM3Module?
        XCTAssertNil(m3_ParseModule(environment, &module, importedAddBytes, UInt32(importedAddBytes.count)))
        XCTAssertNil(m3_LoadModule(runtime, module))

        // The imported function needs to linked before the exported function can be referenced.
        XCTAssertNil(m3_LinkRawFunction(
            module, "imports", "imported_add_func", "i(i I)", importedAdd(runtime:stackPointer:memory:)
        ))

        var integerProviderFunction: IM3Function?
        XCTAssertNil(m3_FindFunction(&integerProviderFunction, runtime, "integer_provider_func"))

        let sum = [].withCStrings { (arguments) -> Int32 in
            var mutableArguments = arguments

            let size = UnsafeMutablePointer<Int>.allocate(capacity: 1)
            defer { size.deallocate() }

            let ret = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
            defer { ret.deallocate() }

            XCTAssertNil(wasm3_CallWithArgs(integerProviderFunction, UInt32(0), &mutableArguments, size, ret))
            XCTAssertEqual(MemoryLayout<Int32>.size, size.pointee)
            return ret.pointee
        }

        XCTAssertEqual(-3291, sum)
    }

    static var allTests = [
        ("testCanCreateEnvironmentAndRuntime", testCanCreateEnvironmentAndRuntime),
        ("testCanCallAndReceiveReturnValueFromAdd", testCanCallAndReceiveReturnValueFromAdd),
        ("testCanCallAndReceiveReturnValueFromFibonacci", testCanCallAndReceiveReturnValueFromFibonacci),
        ("testImportingNativeFunction", testImportingNativeFunction),
    ]
}

private func importedAdd(
    runtime: IM3Runtime?,
    stackPointer: UnsafeMutablePointer<UInt64>?,
    memory: UnsafeMutableRawPointer?
) -> UnsafeRawPointer? {
    guard let stackPointer = UnsafeMutableRawPointer(stackPointer) else {
        return UnsafeRawPointer(m3Err_trapUnreachable)
    }

    let first = stackPointer.load(as: Int32.self)
    // wasm3 always aligns the stack to 64 bits
    let second = stackPointer.load(fromByteOffset: MemoryLayout<Int64>.stride, as: Int64.self)
    let sum = Int32(Int64(first) + second)
    stackPointer.storeBytes(of: sum, as: Int32.self)

    return nil
}

extension CWasm3Tests {
    // compile and copy base64 binaries in Bash via:
    // `wat2wasm -o >(base64) path/to/file.wat | pbcopy`

    private enum TestError: Error {
        case couldNotDecodeWasm(String)
        case couldNotLoadResource(String)
    }

    private func addWasm() throws -> Array<UInt8> {
        let base64 = "AGFzbQEAAAABBwFgAn9/AX8DAgEABwcBA2FkZAAACgkBBwAgACABags="
        guard let data = Data(base64Encoded: base64) else { throw TestError.couldNotDecodeWasm("add.wasm") }
        return Array<UInt8>(data)
    }

    private func fibonacciWasm() throws -> Array<UInt8> {
        let base64 = "AGFzbQEAAAABBgFgAX4BfgMCAQAHBwEDZmliAAAKHwEdACAAQgJUBEAgAA8LIABCAn0QACAAQgF9EAB8Dws="
        guard let data = Data(base64Encoded: base64) else { throw TestError.couldNotDecodeWasm("fib64.wasm") }
        return Array<UInt8>(data)
    }

    private func importedAddFunc() throws -> Array<UInt8> {
        let base64 = "AGFzbQEAAAABCwJgAn9+AX9gAAF/Ah0BB2ltcG9ydHMRaW1wb3J0ZWRfYWRkX2Z1bmMAAAMCAQEHGQEVaW50ZWdlcl9wcm92aWRlcl9mdW5jAAEKCwEJAEH7ZUIqEAAL"
        guard let data = Data(base64Encoded: base64) else { throw TestError.couldNotDecodeWasm("imported-add.wasm") }
        return Array<UInt8>(data)
    }
}
